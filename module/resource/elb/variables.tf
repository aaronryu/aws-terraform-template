
variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "environment" {
  type        = string
  description = "environment of alb"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "ids of public subnets for the alb (at least 2 AZs)"
}

variable "alb_sg_id" {
  type        = string
  description = "id of alb security group"
}

variable "target_instance_id" {
  type        = string
  description = "id of the ec2 instance behind the alb"
}

variable "target_instance_port" {
  type        = number
  description = "port the target instance listens on"
  default     = 8080
}

variable "healthcheck_path" {
  type        = string
  description = "path the alb calls to check the target is healthy"
  default     = "/"
}
