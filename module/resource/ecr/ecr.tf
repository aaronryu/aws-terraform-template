
# 도커 이미지 저장소
resource "aws_ecr_repository" "this" {
  name = "${var.project_name}-${var.environment}-app"

  # GitHub Actions 가 같은 이름(latest)으로 계속 덮어써서 Push 하므로 MUTABLE
  image_tag_mutability = "MUTABLE"

  # 실습용 설정: 이미지가 남아 있어도 terraform destroy 로 삭제 가능
  force_delete = true

  # 운영 배포 시 필수로 설정되어야한다 : 비용이 조금 나가긴하지만 Push 할 때마다 알려진 취약점 CVE 스캔
  # image_scanning_configuration {
  #   scan_on_push = true
  # }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Re-run 등으로 태그를 잃은 이미지는 1일 뒤 삭제"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "SHA 태그 이미지는 최근 10개만 유지 (= 최근 10번 배포까지 롤백 가능)"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}