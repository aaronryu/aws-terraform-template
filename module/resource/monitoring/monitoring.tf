
# ─────────────────────────────────────────────────────────────
# 알람이 오는 흐름
#   CloudWatch 메트릭(또는 로그에서 뽑은 메트릭) → 알람(임계값 초과) → SNS 토픽 → 이메일
# ─────────────────────────────────────────────────────────────

# 1. SNS 토픽: 알람을 받아 구독자들에게 뿌려주는 "알림 채널"
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-alerts"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# - ② CloudWatch 매트릭 알람 연결 ∋→ [SNS 토픽] ←∈ ① 이메일 구독 연결 중
# ① 이메일 구독을 토픽 내 추가: apply 후 AWS 가 보내는 "Subscription Confirmation" 메일의 Confirm 링크를 눌러야 활성화된다.
# (확인 전에는 "PendingConfirmation" 상태라 알람 메일이 오지 않는다)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# 2. ECS 서비스 메트릭 알람 (AWS/ECS 네임스페이스: 추가 설정 없이 1분 간격으로 자동 수집됨)
#    - 메트릭 값: 태스크 정의(Task Definition)에 할당된 총 용량 대비 실제 사용 중인 리소스의 비율(%) (실사용량 / 할당된 용량 * 100)
#    - 활용 목적: 수집된 지표를 분석하여 태스크의 CPU 및 메모리 스펙(Task Size)이 과다 할당(비용 낭비)되었거나 과소 할당(성능 저하/OOM)되었는지 판단하고 리사이징(Right-sizing)하는 근거로 활용
locals {
  ecs_alarms = {
    cpu = {
      metric_name = "CPUUtilization"
      threshold   = var.cpu_threshold_percent
    }
    memory = {
      metric_name = "MemoryUtilization"
      threshold   = var.memory_threshold_percent
    }
  }
}

# - ② CloudWatch 매트릭 알람 연결 ∋→ [SNS 토픽] ←∈ ① 이메일 구독 연결 중
# ② CloudWatch 매트릭 알람 정의 (CPU / Memory) 후 특정 상태에 [SNS 토픽] 연결
resource "aws_cloudwatch_metric_alarm" "ecs" {
  for_each = local.ecs_alarms

  alarm_name          = "${var.project_name}-${var.environment}-ecs-${each.key}-high"
  alarm_description   = "ECS service ${each.value.metric_name} >= ${each.value.threshold}% for 3 minutes"
  namespace           = "AWS/ECS"
  metric_name         = each.value.metric_name
  statistic           = "Average"
  period              = 60 # 초 단위 집계 구간
  evaluation_periods  = 3  # 연속 3번(=3분) 임계값을 넘으면 ALARM (순간적인 튐은 무시)
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  # 태스크가 없어서 데이터가 비는 구간(배포 중, 중지 등)은 정상으로 취급
  treat_missing_data = "notBreaching"

  # 상태 전이 타입들이 있어서 원하는 상태에만 알림을 별개 설정할 수 있다
  alarm_actions = [aws_sns_topic.alerts.arn] # ALARM 으로 바뀔 때 알림
  ok_actions    = [aws_sns_topic.alerts.arn] # 다시 OK 로 돌아올 때도 알림

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-${each.key}-high"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 3. 로그 → 메트릭 → 알람: 애플리케이션 로그에 "ERROR" 가 찍히면 숫자(메트릭)로 바꿔 알람을 건다.
locals {
  error_metric_namespace = "${var.project_name}/${var.environment}"
  error_metric_name      = "AppErrorCount"
}

resource "aws_cloudwatch_log_metric_filter" "app_error" {
  name           = "${var.project_name}-${var.environment}-app-error"
  log_group_name = var.log_group_name
  pattern        = "ERROR" # 로그 한 줄에 대문자 ERROR 가 포함되면 매칭

  metric_transformation {
    name          = local.error_metric_name
    namespace     = local.error_metric_namespace
    value         = "1" # 매칭된 로그 1건당 1 을 더한다
    default_value = "0" # 매칭이 없는 구간은 0 으로 기록
  }
}

# resource "aws_cloudwatch_metric_alarm" "ecs" {       -> ecs 명칭이 붙은 이유 : 앱이아니라 ECS 자체 자원에 대한 알람이기 때문
# resource "aws_cloudwatch_metric_alarm" "app_error" { -> app 명칭이 붙은 이유 : 앱 내 발행되는 로그에 대한 알람이기 때문
resource "aws_cloudwatch_metric_alarm" "app_error" {
  alarm_name          = "${var.project_name}-${var.environment}-app-error-logs"
  alarm_description   = "1건 이상의 ERROR 로그가 1분 안에 발생"
  namespace           = local.error_metric_namespace
  metric_name         = local.error_metric_name
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-error-logs"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
