
resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}