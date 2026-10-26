
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = false # 나중에 DNS(Route53) 추가할때 true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 기본 CIDR(10.0.0.0/24)은 /26 서브넷 4개로 이미 가득 찼으므로,
# 데이터베이스 전용 서브넷을 위한 보조 CIDR 을 VPC 에 추가로 연결한다 = 기존 VPC 삭제하고 새 CIDR 가진 VPC 를 만들지 않아도 된다
# * 바로 옆 대역인 10.0.1.0/24 는 쓸 수 없다 (InvalidVpc.Range 오류)
#   - AWS 제한: VPC 에 10.0.0.0/15 범위의 CIDR 이 있으면 10.0.0.0/16 범위(10.0.0.0 ~ 10.0.255.255) 는 보조 CIDR 로 추가 불가
#     - 10.0.1.0/24 로 추가 시 오류 발생해서 -> 10.1.0.0/24 으로 수정
#   - https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html#add-cidr-block-restrictions
resource "aws_vpc_ipv4_cidr_block_association" "database" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.1.0.0/24"
}