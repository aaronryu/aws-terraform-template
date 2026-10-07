
variable "environment" {
  type        = string
  description = "environment of ec2"
  default     = "development"
}

variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "private_route_table_id" {
  type        = string
  description = "private route table for adding ENI of NAT instance"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "ids of private subnet"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "ids of public subnet"
}

variable "bastion_sg_id" {
  type        = string
  description = "id of bastion security group"
}

variable "nat_instance_sg_id" {
  type        = string
  description = "id of nat instance security group"
}

variable "private_server_sg_id" {
  type        = string
  description = "id of private server security group"
}
