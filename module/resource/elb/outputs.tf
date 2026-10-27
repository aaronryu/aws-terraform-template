
# 브라우저에서 http://<이 값> 으로 접속
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

# 브라우저에 바로 붙여 넣을 접속 주소 (리스너 포트를 그대로 가져와 붙인다)
output "production_url" {
  value = "http://${aws_lb.this.dns_name}:${aws_lb_listener.http.port}"
}

# 브라우저에 바로 붙여 넣을 접속 주소 (리스너 포트를 그대로 가져와 붙인다)
output "develop_url" {
  value = "http://${aws_lb.this.dns_name}:${aws_lb_listener.develop.port}"
}

# 본 값을 밖으로 빼내어 ECS 서비스의 load_balancer 블록에 넣도록해 -> ECS 태스크가 이 TG 대상 그룹에 자동 등록되어 ELB 와 연결시킨다
#   - 리스너에 연결되지 않은 대상 그룹을 ECS 서비스에 넣으면 생성 오류가 나므로 리스너가 만들어진 뒤에 값을 넘긴다
output "ecs_target_group_arn" {
  value      = aws_lb_target_group.ecs.arn
  depends_on = [aws_lb_listener.http]
}

output "ec2_target_group_arn" {
  value = aws_lb_target_group.ec2.arn
}
