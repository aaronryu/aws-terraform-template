
output "address" {
  description = "hostname of the db instance"
  value       = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "username" {
  value = aws_db_instance.this.username
}

output "password" {
  value     = random_password.db.result
  sensitive = true
}

# 본 버전에서는 평문 패스워드를 만들어서 사용하지만, RDS 생성 시 Secrets Manager 통해 패스워드를 만들어서 외부 노출없이 EC2 에서 해당 ARN 사용하여 접근 가능
# output "master_user_secret_arn" {
#   description = "arn of the secret in Secrets Manager holding the master username/password"
#   value       = aws_db_instance.this.master_user_secret[0].secret_arn
# }