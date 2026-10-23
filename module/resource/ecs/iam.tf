
locals {
  # ECS 태스크가 맡을 수 있는 역할이라는 신뢰 정책 (실행 역할에 사용)
  # - IAM 에서 Role 역할이라는건 어떤 AWS 서비스(자원)에서도 가져다 쓸 수 있는 정책 집합이기에 위험하게 의도와 다르게 사용될 문제가 있어서 방지가 필요하다
  #    - 그래서 어떤 AWS 서비스에서만 해당 Role 역할을 사용할 수 있는지 제약을 걸기 위해 본 신뢰 관계를 설정한다
  #        - AWS ECS 서비스 내 태스크에서만 본 Role 역할을 사용할 수 있도록 제약을 거는것이다
  # - IAM 콘솔 내 [역할] > 역할 클릭한 다음 > [권한] 바로 옆에 [신뢰 관계]를 누르면 [신뢰할 수 있는 엔터티]
  ecs_tasks_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# 1. 실행 역할(execution role): ECS 가 컨테이너를 "띄우기 위해" 쓰는 권한
#    - ECR 에서 이미지 Pull, CloudWatch 로 로그 전송
#    - 이 ARN 을 GitHub Actions 가 만드는 태스크 정의의 executionRoleArn 에 적는다.
resource "aws_iam_role" "execution" {
  name               = "${var.project_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = local.ecs_tasks_assume_role_policy

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

# 위 AmazonECSTaskExecutionRolePolicy 내에 이미 CloudWatch 로 로그를 전송하는 권한은 있는데
# - awslogs-create-group: true 옵션 사용한다면 로그 적재할 CloudWatch 내 Log Group 존재하지 않을때 생성하기 위한 "logs:CreateLogGroup" 권한을 새로 추가 필요
# - 만약 RDS 사용 시 manage_master_user_password: true 사용 시 비밀번호 자동 생성 후 AWS Secrets Manager 내부에 저장한다
# - AWS ECS 구동을 시작할때 "secretsmanager:GetSecretValue" 권한을 넣어줘야 RDS 서비스가 직접 생성하여 AWS Secrets Manager 내 저장한 마스터 비밀번호를 가져올수있다
#    - ECS 는 그렇게 가져온 RDS 마스터 비밀번호를 ExecutionRole 시점에 컨테이너 구동 환경(도커)에 주입하고 -> 그것은 다시 스프링 부트 실행변수에 넘겨져서 런타임 구동이 된다
