
# 1. Bastion SG: 외부(0.0.0.0/0)로부터 SSH(22) 접속 허용
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security Group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    # description = "SSH from anywhere"
    description = "SSH from AWS Console Instance Connect"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = ["pl-00ec8fd779e5b4175"]
  }

  ingress {
    description = "SSH from developer IPs (house etc)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ips_for_develop_purpose
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-bastion-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 2. NAT Instance SG: Private Subnet 대역에서 오는 모든 트래픽 허용 + AWS EC2 Instance Connect 위해 22 허용
resource "aws_security_group" "nat_instance_sg" {
  name        = "nat-instance-sg"
  description = "Security Group for NAT Instance"
  vpc_id      = var.vpc_id

  ingress {
    # description = "SSH from anywhere"
    description = "SSH from AWS Console Instance Connect"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = ["pl-00ec8fd779e5b4175"]
  }

  ingress {
    description = "Allow all inbound from Private Subnet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-instance-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 3. Private EC2 SG: Bastion SG를 통해서만 SSH(22) 접속 허용
resource "aws_security_group" "private_server_sg" {
  name        = "private-server-sg"
  description = "Security Group for Private Server"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from Bastion Security Group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Bastion SG에 대해서만 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-server-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}