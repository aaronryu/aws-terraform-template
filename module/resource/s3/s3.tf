
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 버킷 이름은 전 세계에서 유일해야 하므로 계정 ID 를 붙여 충돌을 피한다.
resource "aws_s3_bucket" "this" {
  # ② 계정 지역 네임스페이스 적용 방식 < ① Global Namespace / ② Account Regional Namespace 중 2번 선택
  #   : 필수 접미사무(Account-Regional Namespace Suffix) 필요 {}-123456789012-ap-northeast-2-an
  bucket           = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace = "account-regional"

  # 실습용 설정: 객체가 남아 있어도 terraform destroy 로 삭제 가능
  #   - 실제 운영환경에서 이걸 true 로 하게된다면, 매번 S3 서비스 내 모든 이미지 등의 데이터가 싸그리 삭제되어버린다
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-assets"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 공개 읽기는 "버킷 정책" 으로만 허용한다 < 버킷에 대한 퍼블릭 엑세스는 기본적으로 열어두도록 한 뒤
#   - block_public_policy / restrict_public_buckets 를 풀어야 아래 공개 정책을 붙일 수 있다.
#   - ACL 로 공개하는 경로(block_public_acls / ignore_public_acls)는 계속 막아 둔다.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Ⓐ Identity-based Policy 신원 기반 정책 - 권한을 주어주는것
#   - aws_iam_user_policy 계정을 만들어 비밀번호 혹은 엑세스 키 셋을 통해 접근
#   - aws_iam_role_policy 역할을 만들어 임시적으로 붙여 사용하는 것

# Ⓑ Resource-based Policy 리소스 기반 정책 - AWS 서비스에 접근하는것들에 대해 어떤 권한을 열어둘것인지
#   - aws_s3_bucket_policy
#     : 누구나 객체를 "읽기(GetObject)" 만 가능. 목록 조회(ListBucket), 업로드, 삭제는 허용하지 않는다.
#       (공개 범위를 줄이려면 Resource 를 "${aws_s3_bucket.this.arn}/public/*" 처럼 접두사로 좁힌다)
#       · 여기서 추가적으로 특정 계정(user) 혹은 역할(role)가진 타 리소스에게만 업로드, 삭제 권한을 허용해준다
#           s3:GetObject
#           s3:PutObject
#           s3:DeleteObject
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })

  # 공개 차단 설정이 먼저 풀려 있어야 정책을 붙일 수 있다.
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# CORS: 허용한 도메인의 "웹 페이지 안 JavaScript(fetch/XHR)" 가 이 버킷을 호출하도록 브라우저에 알려 준다.
# 접근을 막는 장치가 아니다. URL 을 직접 열거나 <img> 로 불러오는 것은 CORS 와 무관하게 가능하다.
resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_origins = var.cors_allowed_origins
    allowed_methods = var.cors_allowed_methods
    allowed_headers = ["*"]
    # allowed_headers = [
    #   "Content-Type",
    #   "Authorization",
    #   "x-amz-date",
    #   "x-amz-content-sha256"
    # ]
    expose_headers = [
      "ETag",             # 파일의 고유 식별자
      "x-amz-version-id", # 버전 정보
      "x-amz-request-id"  # 요청 추적용 ID
    ]
    # expose_headers = ["ETag"]
    max_age_seconds = 3000
  }
}

# 저장 시 암호화 (SSE-S3: 공개 읽기와 함께 써도 S3 가 자동으로 복호화해 내려준다)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      # kms_master_key_id = "" # SSE-KMS 사용 시 어떤 KMS 키를 사용할것인지 명시
    }
  }
  # bucket_key_enabled = true # SSE-KMS 사용 시 매번 파일 CRUD 호출 시 KMS 쓰지않고 버킷 레벨 KMS 만들어 캐시하도록
}