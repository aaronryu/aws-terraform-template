
output "bastion_public_ip" {
  value = module.ec2_instances.bastion_public_ip
}

output "private_server_private_ip" {
  value = module.ec2_instances.private_server_private_ip
}

# Bastion 을 거쳐 Private EC2 로 접속하는 2단계 명령 (프로젝트 루트에서, terraform output -raw <이름> 으로 꺼내 실행)
# 1) 터미널 A: 로컬 33322 포트 → Bastion → Private EC2 의 22 포트로 터널을 연다 (-N: 원격 명령 없이 터널만 유지, 끄면 Ctrl+C)
#   - 터미널에 다음 명령어 수행 > eval "$(terraform output -raw ssh_tunnel_to_private_server)"
output "ssh_tunnel_to_private_server" {
  value = "ssh -i local-to-bastion.pem -N -L 33322:${module.ec2_instances.private_server_private_ip}:22 ec2-user@${module.ec2_instances.bastion_public_ip}"
}

# 2) 터미널 B: 열린 터널(localhost:33322)로 Private EC2 에 접속
# * 인스턴스가 재생성되면 localhost:33322 의 호스트 키가 바뀌므로 known_hosts 에 남기지 않는다
# = StrictHostKeyChecking=no + UserKnownHostsFile=/dev/null 옵션 덕분에 localhost:33322 의 호스트 키가 바뀌어도 known_hosts 에 남기지 않아 오류 발생 방지
#   - 터미널에 다음 명령어 수행 > eval "$(terraform output -raw ssh_to_private_server)"
output "ssh_to_private_server" {
  value = "ssh -i local-to-private.pem -p 33322 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@localhost"
}

# ALB 도입되고나서는 단일 도메인명으로 웹브라우저나 클라이언트로 접속하게 된다 - 재배포되어도 변하지않는다
output "alb_dns_name" {
  value = module.elb.alb_dns_name
}

output "production_url" {
  value = "${module.elb.production_url}/files/page"
}

output "develop_url" {
  value = "${module.elb.develop_url}/files/page"
}

# ECS 대상 그룹 헬스체크 상태 확인용 > aws elbv2 describe-target-health --target-group-arn $(terraform output -raw ecs_target_group_arn)
output "ecs_target_group_arn" {
  value = module.elb.ecs_target_group_arn
}

# EC2 대상 그룹 헬스체크 상태 확인용 > aws elbv2 describe-target-health --target-group-arn $(terraform output -raw ec2_target_group_arn)
output "ec2_target_group_arn" {
  value = module.elb.ec2_target_group_arn
}

output "rds_dns_name" {
  value = module.rds.address
}

# 로컬 DB 클라이언트(DBeaver 등)에서 Bastion 을 거쳐 RDS 로 접속하기 위한 터널 (프로젝트 루트에서 실행)
# - 로컬 25432 포트 → Bastion → RDS 의 5432 포트로 터널을 연다 (-N: 원격 명령 없이 터널만 유지, 끄면 Ctrl+C)
#   - 터미널에 다음 명령어 수행 > eval "$(terraform output -raw ssh_tunnel_to_rds)"
# - 터널이 열린 상태에서 DBeaver 로 localhost:25432 접속
output "ssh_tunnel_to_rds" {
  value = "ssh -i local-to-bastion.pem -N -L 25432:${module.rds.address}:${module.rds.port} ec2-user@${module.ec2_instances.bastion_public_ip}"
}

# Ⓐ GitHub Variables 에 등록할 Variables 값
#   - 명령어 입력 시 값들 일괄 출력: terraform output -json github_actions_vars
#   - Github Actions 워크플로우가 GitHub Variables 내 저장된 이 키 이름 그대로 ${{ vars.<KEY> }} 로 읽어 컨테이너의 런타임 환경 변수로 넣는다.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "github_actions_vars" {
  value = {
    AWS_REGION             = data.aws_region.current.region
    AWS_ACCOUNT_ID         = data.aws_caller_identity.current.account_id
    AWS_S3_BUCKET          = module.s3.bucket_name
    ECR_REGISTRY           = module.ecr.registry
    ECR_REPOSITORY         = module.ecr.repository_name
    ECR_REPOSITORY_URL     = module.ecr.repository_url
    ECS_CLUSTER            = module.ecs.cluster_name
    ECS_SERVICE            = module.ecs.service_name
    ECS_TASKDEF            = module.ecs.task_definition
    ECS_CONTAINER          = module.ecs.container_name
    ECS_EXECUTION_ROLE_ARN = module.ecs.execution_role_arn
  }
}

# Ⓑ GitHub Secrets 에 등록할 Secrets 값 (비밀번호 포함이라 sensitive: 평소엔 <sensitive> 로 가려짐)
#   - 명령어 입력 시 값들 일괄 출력: terraform output -json github_actions_secrets
#   - Github Actions 워크플로우가 GitHub Secrets 내 저장된 이 키 이름 그대로 ${{ secrets.<KEY> }} 로 읽어 컨테이너의 런타임 환경 변수로 넣는다.
output "github_actions_secrets" {
  sensitive = true
  value = {
    # * 주의 : Github Secrets 내에서 추후 ECR 업로드 / ECS 구동을 위해 필요한 IAM 사용자 계정의 Access Key / Secret Key 는 직접 Github 페이지에서 추가해야합니다
    # - AWS_ACCESS_KEY_ID
    # - AWS_SECRET_ACCESS_KEY
    # 스프링 spring.datasource.* 가 읽는 이름 그대로
    DATASOURCE_URL      = "jdbc:postgresql://${module.rds.address}:${module.rds.port}/${module.rds.db_name}"
    DATASOURCE_USERNAME = module.rds.username
    DATASOURCE_PASSWORD = module.rds.password
    # 일반적 AWS_ 가 아닌 APP_AWS_ 접두사가 붙은 키인 이유: Github Actions 워크플로우가 배포할 때 쓰는 AWS_ACCESS_KEY_ID 과 이름이 겹치지 않도록
    # 워크플로우가 태스크 정의서 JSON 내 변수를 채울때 Spring Boot 컨테이너의 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 설정변수명에 아래의 값을 주입해준다
    APP_AWS_ACCESS_KEY_ID     = module.ec2_instances.app_access_key_id
    APP_AWS_SECRET_ACCESS_KEY = module.ec2_instances.app_secret_access_key
  }
}