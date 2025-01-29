variable "environment" {
    type = string
    description = "environment of sg"
    default = "development"
}

variable "vpc_id" {
    type = string
    description = "id of vpc"
}