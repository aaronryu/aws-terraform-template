
variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "environment" {
  type        = string
  description = "environment of security group"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr of vpc"
}

variable "ips_for_develop_purpose" {
  type        = list(string)
  description = "ssh from certain ips"
}

variable "app_port" {
  type        = number
  description = "port the private server listens on (alb forwards to this port)"
  default     = 8080
}
