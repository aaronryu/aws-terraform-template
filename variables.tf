
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

# - 1차: S3 + RDS

variable "cors_allowed_origins" {
  type        = list(string)
  description = "web page origins allowed to call the S3 bucket from the browser, e.g. [\"https://www.example.com\"]"
  default     = ["http://localhost:3000"]
}
