output "server_sg_id" {
    value = aws_security_group.server.id
}

output "rds_sg_id" {
    value = aws_security_group.rds.id
}

output "bastion_sg_id" {
    value = aws_security_group.bastion.id
}

