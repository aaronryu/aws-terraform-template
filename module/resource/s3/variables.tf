
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

# app_user_name  - [방식 A - IAM USER] 버킷 권한을 붙일 스프링 앱용 IAM 사용자 이름
variable "app_user_name" {
  type        = string
  description = "iam user name of the app that needs read/write access to the bucket"
}

# app_role_names - [방식 B - IAM ROLE] 버킷 권한을 붙일 EC2 인스턴스 프로파일(바구니) 내 포함되어있는 IAM 역할 이름
# variable "app_role_names" {
#   type        = map(string)
#   description = "iam role names that need read/write access to the bucket"
#   default     = {}
# }