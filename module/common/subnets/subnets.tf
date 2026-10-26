
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-1"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.0.64/26"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-2"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.0.128/26"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-subnet-1"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.0.192/26"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-subnet-2"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 데이터베이스 전용 사설 서브넷 (보조 CIDR 10.0.1.0/24 사용)
# RDS 의 DB 서브넷 그룹은 서로 다른 AZ 의 서브넷이 최소 2개 필요하다.
resource "aws_subnet" "database_subnet_1" {
  vpc_id                  = var.database_vpc_id
  cidr_block              = "10.0.1.0/26"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-subnet-1"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id                  = var.database_vpc_id
  cidr_block              = "10.0.1.64/26"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-subnet-2"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

