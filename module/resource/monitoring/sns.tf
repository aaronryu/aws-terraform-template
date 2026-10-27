
# SNS 토픽 생성: 알람을 받아 구독자들에게 뿌려주는 "알림 채널"
#   - cloudwatch.tf 의 알람들이 상태가 바뀔 때 이 토픽으로 보낸다 (alarm_actions / ok_actions)
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-alerts"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# ② CloudWatch 매트릭 알람 연결 ∋→ [SNS 토픽] ←∈ ① 이메일 구독 연결 중
#   - ① 이메일 구독을 토픽 내 추가: apply 후 AWS 가 보내는 "Subscription Confirmation" 메일의 Confirm 링크를 눌러야 활성화된다.
#       (확인 전에는 "PendingConfirmation" 상태라 알람 메일이 오지 않는다)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
