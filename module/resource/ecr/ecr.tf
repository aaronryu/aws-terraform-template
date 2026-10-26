
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
        description  = "태그 없는 이미지(덮어써진 이전 latest, 빌드 중간 산물)는 7일 뒤 삭제"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "그 외 모든 이미지는 최근 20개만 유지 (롤백 대상)"
        selection = {
          tagStatus   = "any" # "any" 규칙은 반드시 가장 마지막(가장 큰 priority) 이어야 함
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = { type = "expire" }
      }
    ]
  })
}