
variable "project_name" {
  type        = string
  description = "prefix of resource names (lowercase letters, numbers, hyphens)"
  default     = "tf-practice"
}

variable "container_port" {
  type        = number
  description = "port the container listens on"
  default     = 8080
}
