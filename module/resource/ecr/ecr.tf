
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

# GitHub Actions 워크플로우가 매번 돌아가면서 이미지를 계속 ECR 내 적재하니 주기적으로 지워줘야한다
#   - 동일 이미지 태그값(커밋 SHA 해시값)을 갖고있는 경우 : Github Actions 에서 같은 커밋으로 Re-run 반복 배포 진행했을시 이미지 태그(커밋 SHA 해시값) 생성 - Untagged 처리
#   - 다른 이미지 태그값(커밋 SHA 해시값)이 새로 생성된 경우 : Github Actions 에서 (정상 케이스) 매번 새 커밋으로 배포 진행했을시 - 구 이미지 처리
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