
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
