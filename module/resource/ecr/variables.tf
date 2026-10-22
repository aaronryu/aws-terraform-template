
variable "environment" {
  type        = string
  description = "environment of ecr"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}
