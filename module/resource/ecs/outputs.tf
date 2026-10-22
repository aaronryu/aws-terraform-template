
output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

# GitHub Actions 가 만드는 태스크 정의의 executionRoleArn 에 적을 값
output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}
