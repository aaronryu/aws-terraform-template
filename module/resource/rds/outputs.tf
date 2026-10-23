
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

output "master_user_secret_arn" {
  description = "arn of the secret in Secrets Manager holding the master username/password"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
