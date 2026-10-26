
output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

# 데이터베이스를 위한 보조 CIDR 연결이 끝난 뒤 DB 서브넷을 만들도록 순서를 강제하기 위해 outputs.tf 으로 밖으로 보내 데이터베이스 생성 시 파라미터로 사용
output "database_vpc_id" {
  description = "vpc id, available only after the secondary cidr block is associated"
  value       = aws_vpc_ipv4_cidr_block_association.database.vpc_id
}