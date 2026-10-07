
output "vpc_id" {
  description = "vpc id"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "cidr of vpc"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "ids of public subnets"
  value       = module.subnets.public_subnet_ids
}

output "public_route_table_id" {
  description = "id of public route table for pulic subnets"
  value       = module.route_table.public_route_table_id
}

output "private_subnet_ids" {
  description = "ids of private subnets"
  value       = module.subnets.private_subnet_ids
}

output "private_route_table_id" {
  description = "id of private route table for private subnets"
  value       = module.route_table.private_route_table_id
}
