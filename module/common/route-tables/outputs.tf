output "pub_rt_id" {
    value = aws_route_table.public_route_table.id  
}

output "pri_rt_id" {
    value = aws_route_table.private_route_table.id  
}