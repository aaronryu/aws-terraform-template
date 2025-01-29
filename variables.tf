# terraform.tfvars 통해 아래 파라미터값들을 주입해주면되는데 번거롭지않게 디폴트값들로 채워넣어놓긴했다

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names (lowercase letters, numbers, hyphens)"
  default     = "tf-practice"
}

variable "ips_for_develop_purpose" {
  type        = list(string)
  description = "ssh from certain ips"
}