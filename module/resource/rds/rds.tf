
# 1. DB 서브넷 그룹: RDS 가 놓일 수 있는 서브넷 후보 목록 (서로 다른 AZ 의 서브넷이 최소 2개 필요)
#   - EC2 는 단일 인스턴스이기에 특정 가용 영역의 서브넷 1개에만 할당하는데
#   - RDS 는 관리형 서비스라 장애가 발생했을떄 다른 가용 영여긍로 자동 페일오버 수행을 위해 서브넷 2개 이상이 필요
#     - aws_db_instance 정의 시 multi_az = true 사용과 상관없이 Multi AZ 서브넷 그룹이 아니면 테라폼 실행 시 오류 발생
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for PostgreSQL (database subnets only)"
  subnet_ids  = var.database_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#%^&*()-_=+" # RDS 금지 문자 / $ @ " 공백 제외 - $ 의 경우 Github Actions 에서 사용할때 문제 발생 가능
}

# 2. PostgreSQL 인스턴스 (단일 AZ, 데이터베이스 서브넷 중 availability_zone 에 해당하는 서브넷에 배치)
resource "aws_db_instance" "this" {
  identifier        = "${var.project_name}-${var.environment}-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  # 비밀번호를 코드/tfvars 에 적지 않고, RDS 가 Secrets Manager 에 직접 생성/보관하게 하는 방법
  # (JSON 형태 {"username": "...", "password": "..."} 로 저장됨)
  # manage_master_user_password = true
  # 이렇게 설정하면 좋은것은 Github Actions 내 Taskdef 파일 만들때 비밀번호 주입없이 AWS Secrets Manager 비밀번호값 ARN 그대로 사용

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_sg_id]
  availability_zone      = var.availability_zone
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period    = 1
  auto_minor_version_upgrade = true
  apply_immediately          = true

  # 실습용 설정: terraform destroy 가 막히지 않도록 함 (운영 환경에서는 반대로 설정)
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
