
output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

# CloudWatch 커스텀 대시보드 구성을 위해 여러 알람명들을 모두 outputs.tf 통해 반환하도록 한다
# 1) CPU 알람명
output "cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.ecs["cpu"].alarm_name
}

# 2) Memeory 알람명
output "memory_alarm_name" {
  value = aws_cloudwatch_metric_alarm.ecs["memory"].alarm_name
}

# 3) ERROR 로그 알람명
output "error_alarm_name" {
  value = aws_cloudwatch_metric_alarm.app_error.alarm_name
}
