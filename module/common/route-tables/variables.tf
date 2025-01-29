variable "vpc_id" {
      type = string
      description = "id of vpc"
}

variable "igw_id" {
    type = string
    description = "id of internet gateway"
}

variable "environment" {
    type = string
    description = "environment of route table"
    default = "development"
}