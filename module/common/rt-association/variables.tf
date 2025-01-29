variable "vpc_id" {
    type = string
    description = "id of vpc"
}

variable "environment" {
    type = string
    default = "development"
}

variable "pub_rt_id" {
    type = string
    description = "id of public route table"
}

variable "pri_rt_id" {
    type = string
    description = "id of private route table"  
}

variable "pub_sub_0_id" {
    type = string
    description = "id of public subnet 0"  
}

variable "pub_sub_1_id" {
    type = string
    description = "id of public subnet 1"  
}

variable "pri_sub_0_id" {
    type = string
    description = "id of private subnet 0"  
}

variable "pri_sub_1_id" {
    type = string
    description = "id of private subnet 1"  
}