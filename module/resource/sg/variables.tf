
variable "environment" {
  type        = string
  description = "environment of security group"
  default     = "development"
}

variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr of vpc"
}
