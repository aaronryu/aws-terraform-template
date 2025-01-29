variable "environment" {
    type = string
    description = "environment of ec2"
    default = "development"
}

variable "vpc_id" {
    type = string
    description = "id of vpc"
}

variable subnet_id {
    type = string
    description = "id of subnet"
}

variable "server_sg_id" {
    type = string
    description = "id of server security group"
}

variable "bastion_sg_id" {
    type = string
    description = "id of bastion security group"  
}
