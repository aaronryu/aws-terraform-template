
resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name        = "public-route-table"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "private-route-table"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# DB 서브넷용 라우팅 테이블: VPC 내부(local) 라우트만 존재하고 인터넷(0.0.0.0/0) 경로는 없다.
resource "aws_route_table" "database_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "database-route-table"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}