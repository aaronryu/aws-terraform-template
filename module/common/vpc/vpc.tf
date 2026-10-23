
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = false # 나중에 DNS(Route53) 추가할때 true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name        = "terraform-vpc"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 기본 CIDR(10.0.0.0/24)은 /26 서브넷 4개로 이미 가득 찼으므로,
# 데이터베이스 전용 서브넷을 위한 보조 CIDR 을 VPC 에 추가로 연결한다. (VPC 를 새로 만들지 않아도 됨)
resource "aws_vpc_ipv4_cidr_block_association" "database" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
}
