
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = false # 나중에 DNS(Route53) 추가할때 true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name        = "terraform-vpc"
    ManagedBy   = "aaron"
    Environment = "${var.environment}"
  }
}
