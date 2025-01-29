variable "vpc_id" {
    type = string
    description = "vpc id of Internet gateway"
}

variable "environment" {
    type = string
    description = "environment of igw"
    default = "development"
}