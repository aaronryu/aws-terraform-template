/*

    vpc setup:
    - 1 vpc, no NAT gateway
    - declare "module" at main configuration tf file.

*/

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/24" 
  enable_dns_hostnames = false # 나중에 DNS(route 53)추가할때 true로
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name                = "alyes-b-dev-terraform-vpc"
    ManagedBy           = "CY-terraform"
    Environment = "${var.environment}"
  }
}
