
output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "nat_instance_sg_id" {
  value = aws_security_group.nat_instance_sg.id
}

output "private_server_sg_id" {
  value = aws_security_group.private_server_sg.id
}

output "database_sg_id" {
  value = aws_security_group.database_sg.id
}

output "ecs_task_sg_id" {
  value = aws_security_group.ecs_task_sg.id
}
