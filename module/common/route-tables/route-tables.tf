resource "aws_route_table" "public_route_table" {
    vpc_id = var.vpc_id

# 문제가 있다면 여기서 gw id가 ""의 밖에 있어야?
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }


    tags = {
      Name = "public-route-table"
      ManagedBy = "CY-Terraform"
      Environment = var.environment
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = var.vpc_id

    tags = {
      Name = "private-route-table"
      ManagedBy = "CY-Terraform"
      Environment = var.environment
    }
}