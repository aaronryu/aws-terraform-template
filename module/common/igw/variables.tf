
variable "vpc_id" {
  type        = string
  description = "vpc id of internet gateway"
}

variable "environment" {
  type        = string
  description = "environment of resource"
  default     = "development"
}