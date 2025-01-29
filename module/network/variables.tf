
variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "environment" {
  type        = string
  description = "environment of resource"
  default     = "dev"
}