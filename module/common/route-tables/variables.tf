
variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "igw_id" {
  type        = string
  description = "id of internet gateway"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "environment" {
  type        = string
  description = "environment of route table"
  default     = "dev"
}