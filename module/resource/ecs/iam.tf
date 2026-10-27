
# 1. 실행 역할(execution role): ECS 가 컨테이너를 "띄우기 위해" 쓰는 권한 = ECR 에서 이미지 Pull, CloudWatch 로 로그 전송
# 2. 태스크 역할(task role): 컨테이너 안의 앱이 S3 같은 AWS 서비스에 접근할 때 쓰는 권한
resource "aws_iam_role" "execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  # IAM Role 역할은 어떤 AWS 서비스에서도 가져다 쓸 수 있어가지고 별의별 AWS 서비스로부터 오남용될 가능성이 있어서 특전 AWS 서비스에서만 사용가능하도록 제약
  # : IAM 콘솔 내 [역할] > 역할 클릭한 다음 > [권한] 바로 옆에 [신뢰 관계]를 누르면 [신뢰할 수 있는 엔터티] 내 어떤 AWS 서비스에서 사용가능 Role 역할인지 명시
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        # 본 IAM Role 역할을 사용할 수 있는 AWS 서비스를 명시: AWS ECS 태스크 - "ecs-tasks.amazonaws.com"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-execution-role"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  # 다음과 같은것 Action   = [
  #   "ecr:GetAuthorizationToken",
  #   "ecr:BatchCheckLayerAvailability",
  #   "ecr:GetDownloadUrlForLayer",
  #   "ecr:BatchGetImage",
  #   "logs:CreateLogStream",
  #   "logs:PutLogEvents"
  # ]
}