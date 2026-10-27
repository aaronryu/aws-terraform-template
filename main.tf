module "network" {
  source       = "./module/network"
  project_name = var.project_name
  environment  = "development"
}

module "security_groups" {
  source                  = "./module/resource/sg"
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = module.network.vpc_cidr
  ips_for_develop_purpose = var.ips_for_develop_purpose
  app_port                = var.target_instance_port
  project_name            = var.project_name
  environment             = var.environment
}

# RDS(PostgreSQL): 데이터베이스 전용 사설 서브넷에 배치, Private EC2 의 SG 에서만 접근 가능
module "rds" {
  source              = "./module/resource/rds"
  project_name        = var.project_name
  database_subnet_ids = module.network.database_subnet_ids
  database_sg_id      = module.security_groups.database_sg_id
  environment         = var.environment
}

module "ec2_instances" {
  source                 = "./module/resource/ec2"
  vpc_id                 = module.network.vpc_id
  private_route_table_id = module.network.private_route_table_id
  private_subnet_ids     = module.network.private_subnet_ids
  public_subnet_ids      = module.network.public_subnet_ids
  bastion_sg_id          = module.security_groups.bastion_sg_id
  nat_instance_sg_id     = module.security_groups.nat_instance_sg_id
  private_server_sg_id   = module.security_groups.private_server_sg_id
  project_name           = var.project_name
  environment            = var.environment
}

# ALB: 인터넷 → (공개 서브넷) ALB ─┬─ :80   → (사설 서브넷) ECS Fargate 태스크 [production]
#                             └─ :8080 → (사설 서브넷) Private EC2       [develop]
module "elb" {
  source               = "./module/resource/elb"
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  alb_sg_id            = module.security_groups.alb_sg_id
  # - Ⓐ Server 서버 기반 = EC2
  target_instance_port = var.target_instance_port
  target_instance_id   = module.ec2_instances.private_server_id
  # - Ⓑ Serverless 서버리스 기반 = FARGATE
  target_port          = var.target_instance_port
  healthcheck_path     = "/actuator/health" # 스프링 앱에 설정한 actuator API 사용
  project_name         = var.project_name
  environment          = var.environment
}

# S3: EC2 내 스프링 어플리케이션이 사용할 파일 저장소 - 위에서 배포된 ALB 도메인명을 그대로 호스트로
module "s3" {
  source               = "./module/resource/s3"
  project_name         = var.project_name
  environment          = var.environment
  cors_allowed_methods = var.cors_allowed_methods
  cors_allowed_origins = flatten([
    var.cors_allowed_origins,
    "http://${module.elb.alb_dns_name}",
    "https://${module.elb.alb_dns_name}",
    "http://${module.elb.alb_dns_name}:8080",
  ])
  app_user_name = module.ec2_instances.app_user_name # [방식 A - IAM USER] 버킷 권한을 붙일 스프링 앱용 IAM 사용자
  # app_role_names       = {                         # [방식 B - IAM ROLE] 인스턴스 프로파일 사용 시 주석 해제
  #   ec2 = module.ec2_instances.private_server_role_name
  #   # ecs = module.ecs.task_role_name # 나중에 ECS 붙일 때 한 줄 추가
  # }
}

# ECR: 도커 이미지 저장소
module "ecr" {
  source       = "./module/resource/ecr"
  project_name = var.project_name
  environment  = var.environment
}

# ECS(Fargate): 사설 서브넷에서 단일 컨테이너 실행, RDS/S3 연결 정보를 주입 + ALB 대상 그룹에 자동 등록
module "ecs" {
  source             = "./module/resource/ecs"
  project_name       = var.project_name
  environment        = var.environment
  # public_subnet_ids = module.network.public_subnet_ids # ELB 연결하지 않고 ECS 자체적으로만 서비스하는 경우 Public Subnet 내 위치
  private_subnet_ids = module.network.private_subnet_ids # ELB - ECS 연결하여 서비스하는 경우 ECS 는 Private Subnet 내 위치
  ecs_task_sg_id     = module.security_groups.ecs_task_sg_id
  ecr_repository_url = module.ecr.repository_url
  target_group_arn   = module.elb.ecs_target_group_arn # ELB 로드밸런서가 바라보는 TG 타겟그룹에 ECS 연결
  container_port     = var.target_instance_port
  cpu                = var.ecs_task_cpu
  memory             = var.ecs_task_memory
}

# CloudWatch 알람 + SNS 이메일 알림: ECS 의 CPU/메모리 사용률, ERROR 로그
module "monitoring" {
  source         = "./module/resource/monitoring"
  project_name   = var.project_name
  alarm_email    = var.alarm_email
  cluster_name   = module.ecs.cluster_name
  service_name   = module.ecs.service_name
  log_group_name = module.ecs.log_group_name
  environment    = var.environment
}