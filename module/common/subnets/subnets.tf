
resource "aws_subnet" "public_subnet_1" {
    vpc_id                  = var.vpc_id
    cidr_block              = "10.0.0.0/26" 
    availability_zone       = "ap-northeast-2a"
    map_public_ip_on_launch = false

    tags = {
        Name                = "terraform-public-subnet-1"
        ManagedBy           = "aaron"
        Environment         = var.environment
    }
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id                  = var.vpc_id
    cidr_block              = "10.0.0.64/26" 
    availability_zone       = "ap-northeast-2b"
    map_public_ip_on_launch = false

    tags = {
        Name                = "terraform-public-subnet-2"
        ManagedBy           = "aaron"
        Environment         = var.environment
    }
}

resource "aws_subnet" "private_subnet_1" {
    vpc_id                  = var.vpc_id
    cidr_block              = "10.0.0.128/26" 
    availability_zone       = "ap-northeast-2a"
    map_public_ip_on_launch = false

    tags = {
        Name                = "terraform-private-subnet-1"
        ManagedBy           = "aaron"
        Environment         = var.environment
    }
}

resource "aws_subnet" "private_subnet_2" {
    vpc_id                  = var.vpc_id
    cidr_block              = "10.0.0.192/26" 
    availability_zone       = "ap-northeast-2b"
    map_public_ip_on_launch = false

    tags = {
        Name                = "terraform-private-subnet-2"
        ManagedBy           = "aaron"
        Environment         = var.environment
    }
}

