
variable "project_name" {
  type        = string
  description = "prefix of resource names (lowercase letters, numbers, hyphens)"
  default     = "tf-practice"
}

# 개발하는 여러분들의 집이나 자주가는 카페의 Public IP 추가하여 Bastion 에 접근할 수 있도록 오픈
#   - Private Subnet 내 위치한 AWS EC2 혹은 AWS RDS 모두 직접 SSH 으로 붙을 수 없고 특정 IP 에 오픈된 Bastion 통해서만 접근가능
variable "ips_for_develop_purpose" {
  type        = list(string)
  description = "ssh from certain ips"
  default     = [
    # "112.216.230.34/32", # Jibmusil IP
    "218.156.176.28/32",
  ]
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

# - 2차: ECR + ECS + GitHub Actions

# Fargate 는 "CPU 와 메모리의 허용된 조합" 만 선택할 수 있다. (cpu: 1024 = 1 vCPU, memory: MiB)
#   cpu  256  → memory 512, 1024, 2048
#   cpu  512  → memory 1024 ~ 4096   (1024 단위)
#   cpu 1024  → memory 2048 ~ 8192   (1024 단위)
#   cpu 2048  → memory 4096 ~ 16384  (1024 단위)
#   cpu 4096  → memory 8192 ~ 30720  (1024 단위)
# JVM(Spring Boot 등)은 시작할 때 CPU 를 많이 쓰고 힙 + 메타스페이스로 메모리를 넉넉히 써야 해서,
# 256/512 에서는 느리거나 OOM(종료 코드 137)으로 죽기 쉽다. 512/1024 이상에서 시작하길 권장.
variable "ecs_task_cpu" {
  type        = number
  description = "fargate task cpu units"
  default     = 512
}

variable "ecs_task_memory" {
  type        = number
  description = "fargate task memory in MiB"
  default     = 1024
}

# - 3차: CloudWatch + SNS

variable "alarm_email" {
  type        = string
  description = "email address that receives CloudWatch alarm notifications (needs a confirmation click)"
}
