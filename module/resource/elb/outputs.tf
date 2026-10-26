
# 브라우저에서 http://<이 값> 으로 접속
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "ec2_target_group_arn" {
  value = aws_lb_target_group.ec2.arn
}
