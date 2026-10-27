
variable "project_name" {
  type        = string
  description = "prefix of resource names"
}

variable "environment" {
  type        = string
  description = "environment of monitoring"
  default     = "development"
}

variable "alarm_email" {
  type        = string
  description = "email address that receives alarm notifications"
}

variable "cluster_name" {
  type        = string
  description = "name of the ecs cluster to watch"
}

variable "service_name" {
  type        = string
  description = "name of the ecs service to watch"
}

# 앞선 AWS ECS 에서 로그를 적재하는 로그 그룹명 -> CloudWatch 는 해당 로그 그룹 내 ERROR 로그가 있는지를 점검한다
variable "log_group_name" {
  type        = string
  description = "name of the cloudwatch log group of the container"
}

variable "cpu_threshold_percent" {
  type        = number
  description = "cpu utilization (%) at or above which the alarm fires"
  default     = 80
}

variable "memory_threshold_percent" {
  type        = number
  description = "memory utilization (%) at or above which the alarm fires"
  default     = 80
}