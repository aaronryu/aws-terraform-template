
variable "environment" {
  type        = string
  description = "environment of security group"
  default     = "development"
}

variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr of vpc"
}

# 개발하는 여러분들의 집이나 자주가는 카페의 Public IP 추가하여 Bastion 에 접근할 수 있도록 오픈
#   - Private Subnet 내 위치한 AWS EC2 혹은 AWS RDS 모두 직접 SSH 으로 붙을 수 없고 특정 IP 에 오픈된 Bastion 통해서만 접근가능
variable "ips_for_develop_purpose" {
  type        = list(string)
  description = "ssh from certain ips"
}

variable "container_port" {
  type        = number
  description = "port the container listens on"
}
