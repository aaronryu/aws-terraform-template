
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