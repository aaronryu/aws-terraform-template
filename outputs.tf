
output "bastion_public_ip" {
  value = module.ec2_instances.bastion_public_ip
}

output "private_server_private_ip" {
  value = module.ec2_instances.private_server_private_ip
}

# 복사해서 바로 실행 (프로젝트 루트에서): Bastion 을 거쳐 Private EC2 로 접속
output "ssh_to_private_server" {
  value = "ssh -i local-to-private.pem -o ProxyCommand=\"ssh -i local-to-bastion.pem -W %h:%p ec2-user@${module.ec2_instances.bastion_public_ip}\" ec2-user@${module.ec2_instances.private_server_private_ip}"
}

output "rds_endpoint" {
  value = module.rds.address
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

# ---- GitHub Secrets 에 등록할 값 (비밀번호 포함이라 sensitive: 평소엔 <sensitive> 로 가려짐) ----
#   terraform output -json app_config
# 워크플로우가 이 키 이름 그대로 secrets.<KEY> 로 읽어 컨테이너의 런타임 환경 변수로 넣는다.
output "app_config" {
  sensitive = true
  value = {
    DB_HOST     = module.rds.address
    DB_PORT     = tostring(module.rds.port)
    DB_NAME     = module.rds.db_name
    DB_USERNAME = module.rds.username
    DB_PASSWORD = module.rds.password
    S3_BUCKET   = module.s3.bucket_name
    # AWS_ 가 아닌 APP_AWS_ 접두사: 워크플로우가 AWS 에 접속할 때 쓰는 자격증명(OIDC)과 이름이 겹치지 않게 한다.
    # 워크플로우가 컨테이너의 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 로 바꿔서 넣는다.
    APP_AWS_ACCESS_KEY_ID     = module.s3.app_access_key_id
    APP_AWS_SECRET_ACCESS_KEY = module.s3.app_secret_access_key
  }
}

# ---- 2차: GitHub Actions 워크플로우(examples/github-actions/deploy-to-ecs.yml)에 넣을 값 ----

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

# ---- 3차: 로그 / 알람 ----

# 로그를 확인할때 CloudWatch 콘솔에 접속해서 아래 로그명을 찾아 클릭할 수 있도록
output "ecs_log_group_name" {
  value = module.ecs.log_group_name
}

# AWS Lambda 에서 아래 토픽을 구독하거나 / EC2, RDS 등의 알람 설정 시 아래 토픽에 보내도록 설정할수도 있다
output "sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

# 아래 다수의 알람명들을 갖고 여러분 스스로 CloudWatch 커스텀 대시보드 구성이 가능
output "cpu_alarm_name" {
  value = module.monitoring.cpu_alarm_name
}

output "memory_alarm_name" {
  value = module.monitoring.memory_alarm_name
}

output "error_alarm_name" {
  value = module.monitoring.error_alarm_name
}
