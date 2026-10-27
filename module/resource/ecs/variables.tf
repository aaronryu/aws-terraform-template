
variable "environment" {
  type        = string
  description = "environment of ecs"
  default     = "development"
}

variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

# ECS 처음에 등록했을때는 서비스를 제공해야하기때문에 Public Subnet 내 위치시켰었다
# variable "public_subnet_ids" {
#   type        = list(string)
#   description = "ids of public subnets where the tasks run"
# }

# ELB 도입 후에는 ECS 는 Private Subnet 내 위치시키고, ELB 만 외부로 노출하면되는것
variable "private_subnet_ids" {
  type        = list(string)
  description = "ids of private subnets where the tasks run"
}

# 그리하여 Private Subnet 내 위치한 ECS 를 ELB 에 연결하기 위해 ELB 에 연결되어있는 TG 내 ECS 서비스를 등록한다
variable "target_group_arn" {
  type        = string
  description = "arn of the alb target group the service registers tasks to"
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
  default     = 7 # 0 으로 설정 시 만기 없음
}