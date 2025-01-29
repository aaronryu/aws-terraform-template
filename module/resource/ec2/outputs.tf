
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