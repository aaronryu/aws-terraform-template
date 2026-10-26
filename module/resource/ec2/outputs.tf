
output "private_server_id" {
  value = aws_instance.private_server.id
}

# 1.1) SSH Tunneling 을 위한 로컬측의 입구
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

# 1.2) SSH Tunneling 통해 Bastion 인스턴스로부터 향하게 될 Private EC2 의 Private IP
output "private_server_private_ip" {
  value = aws_instance.private_server.private_ip
}

# [방식 A - IAM USER] AWS S3 등 스프링 앱에서 사용할 다양한 AWS 서비스들의 권한을, 본 IAM USER 계정에다가 덧붙이기 위함
output "app_user_name" {
  value = aws_iam_user.app.name
}

# [방식 A - IAM USER] 스프링 앱에서 AWS SDK 사용을 위해 AWS_ACCESS_KEY_ID 설정변수로 주입할 값
output "app_access_key_id" {
  value = aws_iam_access_key.app.id
}

# [방식 A - IAM USER] 스프링 앱에서 AWS SDK 사용을 위해 AWS_SECRET_ACCESS_KEY 설정변수로 주입할 값
output "app_secret_access_key" {
  value     = aws_iam_access_key.app.secret
  sensitive = true
}

# [방식 B - IAM ROLE] 인스턴스 프로파일 사용 시 주석 해제
#                    : AWS S3 등 EC2 에서 사용할 다양한 AWS 서비스들의 권한을, 본 IAM ROLE 역할에다가 덧붙이기 위함
# output "private_server_role_name" {
#   value = aws_iam_role.private_server.name
# }
