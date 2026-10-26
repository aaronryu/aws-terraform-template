
# resource "aws_iam_role_policy" "app_s3" { # < app_role_names [방식 B - IAM ROLE] 인스턴스 프로파일 - 실무 AWS 환경(EC2, ECS, Lambda) 표준
resource "aws_iam_user_policy" "app_s3" { # < app_user_name  [방식 A - IAM USER] 엑세스 / 시크릿 키 - 간편하지만 해킹 우려
  name = "${var.project_name}-${var.environment}-s3-access"
  # role = each.value      # 
  user = var.app_user_name # 

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