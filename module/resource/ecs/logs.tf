
# [3차] 컨테이너의 stdout/stderr 가 모이는 CloudWatch 로그 그룹
# - 로그 그룹을 Terraform 이 만들어 두어야 보존 기간(비용)을 직접 IaC 코드를 통해 관리할 수 있다.
# - 태스크 정의의 logConfiguration(awslogs) 이 이 그룹으로 로그를 보낸다.
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-${var.environment}-app"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "/ecs/${var.project_name}-${var.environment}-app"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
