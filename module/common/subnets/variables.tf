variable "vpc_id" {
    type = string
    description = "vpc id of subnets"
}

variable "environment" {
    type = string
    description = "environment of resource"
    default = "development"
}