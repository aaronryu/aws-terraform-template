
output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

# GitHub Actions 가 태스크 정의를 등록할 때 쓰는 family 명 (Terraform 플레이스홀더와 같은 family 로 개정본이 쌓이게)
output "task_definition" {
  value = aws_ecs_task_definition.app.family
}

# GitHub Actions 태스크 정의 JSON 의 containerDefinitions[].name 에 넣을 값
output "container_name" {
  value = local.container_name
}

# GitHub Actions 가 만드는 태스크 정의의 executionRoleArn 에 적을 값
output "execution_role_arn" {
  value = aws_iam_role.execution.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}