variable "rds_sg_id" {
    type = string
    description = "id of RDS security group"
}

variable "environment" {
    type = string
    default = "development"
}

variable "subnet_group_id" {
    type = list(string)
}