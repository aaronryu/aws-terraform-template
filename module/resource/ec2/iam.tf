
# [방식 A - IAM USER] 스프링 앱용 IAM 사용자 - 액세스 키
#   - 키는 GitHub Secrets → 컨테이너/프로세스 환경 변수로 주입되고, SDK 가 환경 변수에서 자동으로 읽는다.
#   - 주로 EC2 위 앱이 쓰지만, 키는 어느 EC2 에도 묶여 있지 않다 = 키만 있으면 로컬(docker-compose, IDE), GitHub Actions 어디서든 동작
#     (반면 [방식 B - IAM ROLE] 역할은 그 EC2 안에서만 자격증명을 받을 수 있도록 제약을 걸어 탈취 걱정이 없고 타 서비스에서 오용할수도 없다)

# A.1) IAM USER 생성 : 스프링 앱에서 사용할 IAM 사용자 생성 < 수많은 신원 기반 정책(Identity-based)을 추가할 수 있다
#   - module/resource/s3/iam.tf: AWS S3 접근이 필요하다면 본 IAM 사용자에 붙이면된다
resource "aws_iam_user" "app" {
  name = "${var.project_name}-${var.environment}-app"

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
# A.2) IAM USER - 액세스 키 쌍 생성 : 앞서 생성한 스프링 앱에서 사용할 IAM 사용자에 액세스 키 쌍 (Access Key / Secret Key) 생성
#   - aws_iam_instance_profile 명칭 private_server 과의 비교 > aws_iam_access_key 명칭이 app 인 이유: 스프링 APP 에서 사용하는 USER 사용자라서
resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

# [방식 B - IAM ROLE] 인스턴스 프로파일 (현재 주석 처리 - 나중에 사용 시 [방식 A - IAM USER] 주석처리 후 이 주석을 풀어 사용)
#   - Private EC2 위 스프링 앱(JAR 또는 Docker 컨테이너)이 액세스 키 없이 AWS API(S3 등)를 호출하게 해 주는 역할
#     - 스프링 앱이 AWS SDK 사용 시 엑세스 키가 필요하지 않아? 괜찮다
#       > AWS SDK 기본 자격증명 체인에 따라 환경변수 → ~/.aws 프로필 → ECS 자격증명 → 인스턴스 프로파일(IMDS) 순으로 체이닝 순회
#   - AWS SDK 는 환경 변수에 키가 없으면 IMDS(169.254.169.254) 에서 이 역할의 임시 자격증명을 자동으로 받아 쓴다

# B.1) IAM ROLE 생성 : EC2 인스턴스에 붙일 역할 생성
# resource "aws_iam_role" "private_server" {
#   name = "${var.project_name}-${var.environment}-private-server-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action    = "sts:AssumeRole"
#         Effect    = "Allow"
#         Principal = { Service = "ec2.amazonaws.com" }
#       }
#     ]
#   })
#
#   tags = {
#     Name        = "${var.project_name}-${var.environment}-private-server-role"
#     ManagedBy   = "aaron"
#     Environment = var.environment
#   }
# }

# B.1) IAM ROLE - 인스턴스 프로파일 생성 : 앞서 생성한 스프링 앱이 구동되는 EC2 서버에 붙일 인스턴스 프로파일 생성 < ROLE 역할을 인스턴스 프로파일에 담아내기
#   - aws_iam_access_key 명칭 app 과의 비교 > aws_iam_instance_profile 명칭이 private_server 인 이유: EC2 서버에 붙는 ROLE 역할이라서
# resource "aws_iam_instance_profile" "private_server" {
#   name = "${var.project_name}-${var.environment}-private-server-profile"
#   role = aws_iam_role.private_server.name
# }
