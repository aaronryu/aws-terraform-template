
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
