
variable "environment" {
  type        = string
  description = "environment of ecs"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "ids of public subnets where the tasks run"
}

variable "ecs_task_sg_id" {
  type        = string
  description = "id of ecs task security group"
}

variable "ecr_repository_url" {
  type        = string
  description = "url of the ecr repository holding the app image"
}

variable "container_port" {
  type        = number
  description = "port the container listens on"
}

variable "cpu" {
  type        = number
  description = "fargate task cpu units"
  default     = 512
}

variable "memory" {
  type        = number
  description = "fargate task memory in MiB"
  default     = 1024
}

variable "log_retention_days" {
  type        = number
  description = "days to keep container logs in CloudWatch Logs"
  default     = 7 # 만기 없음
}
