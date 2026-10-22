module "network" {
  source      = "./module/network"
  environment = "development"
}

module "security_groups" {
  source         = "./module/resource/sg"
  vpc_id         = module.network.vpc_id
  vpc_cidr       = module.network.vpc_cidr
  container_port = var.container_port
  environment    = "development"
}

# [1차] S3: 서비스가 사용할 파일 저장소
module "s3" {
  source               = "./module/resource/s3"
  project_name         = var.project_name
  cors_allowed_origins = var.cors_allowed_origins
  environment          = "development"
}

# [1차] RDS(PostgreSQL): 데이터베이스 전용 사설 서브넷에 배치, Private EC2 의 SG 에서만 접근 가능
module "rds" {
  source              = "./module/resource/rds"
  project_name        = var.project_name
  database_subnet_ids = module.network.database_subnet_ids
  database_sg_id      = module.security_groups.database_sg_id
  environment         = "development"
}

module "ec2_instances" {
  source                 = "./module/resource/ec2"
  project_name           = var.project_name
  vpc_id                 = module.network.vpc_id
  private_route_table_id = module.network.private_route_table_id
  private_subnet_ids     = module.network.private_subnet_ids
  public_subnet_ids      = module.network.public_subnet_ids
  bastion_sg_id          = module.security_groups.bastion_sg_id
  nat_instance_sg_id     = module.security_groups.nat_instance_sg_id
  private_server_sg_id   = module.security_groups.private_server_sg_id
    environment            = "development"
}

# [2차] ECR: 도커 이미지 저장소
module "ecr" {
  source       = "./module/resource/ecr"
  project_name = var.project_name
  environment  = "development"
}
