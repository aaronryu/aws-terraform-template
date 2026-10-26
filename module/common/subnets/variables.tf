
variable "vpc_id" {
  type        = string
  description = "vpc id of subnets"
}

variable "database_vpc_id" {
  type        = string
  description = "vpc id for database subnets (must be resolved after secondary cidr association)"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "environment" {
  type        = string
  description = "environment of resource"
  default     = "dev"
}