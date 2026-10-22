
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
