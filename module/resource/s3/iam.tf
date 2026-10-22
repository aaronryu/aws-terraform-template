
# Spring Boot 앱(EC2/ECS 의 JAR)이 앱 안의 AWS SDK 로 S3 에 접근할 때 쓰는 IAM 사용자 + 액세스 키.
#   - 키는 GitHub Secrets → 컨테이너/프로세스 환경 변수로 주입되고, SDK 가 환경 변수에서 자동으로 읽는다.
#   - Presigned URL 은 이 사용자의 키로 서명되므로, URL 로 할 수 있는 일도 아래 정책 범위로 제한된다.
resource "aws_iam_user" "app" {
  name = "${var.project_name}-${var.environment}-app"

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 이 버킷에 대해서만 (최소 권한)
resource "aws_iam_user_policy" "app_s3" {
  name = "s3-access"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = ["${aws_s3_bucket.this.arn}"]
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${aws_s3_bucket.this.arn}/*"]
      }
    ]
  })
}

# 액세스 키 쌍. secret 은 terraform.tfstate 에 평문으로 저장되므로 state 파일은 Git 에 올리지 않는다.
resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}
