
output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "nat_instance_sg_id" {
  value = aws_security_group.nat_instance_sg.id
}

output "private_server_sg_id" {
  value = aws_security_group.private_server_sg.id
}
