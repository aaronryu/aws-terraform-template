
variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "public_route_table_id" {
  type        = string
  description = "id of public route table"
}

variable "private_route_table_id" {
  type        = string
  description = "id of private route table"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "ids of public subnet"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "ids of private subnet"
}

variable "database_route_table_id" {
  type        = string
  description = "id of database route table"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "ids of database subnet"
}
