
variable "environment" {
  type        = string
  description = "environment of s3"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "web page origins allowed to call the bucket from the browser (scheme + host [+ port])"
}

variable "cors_allowed_methods" {
  type        = list(string)
  description = "HTTP methods allowed by CORS. add PUT when the browser uploads directly with a presigned URL"
  default     = ["GET", "HEAD"]
}
