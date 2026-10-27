
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

  ingress {
    description     = "HTTP from ALB Security Group"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALB 를 거친 요청만 허용
  }

  # ECR 이미지 Pull, CloudWatch 로그 전송, Secrets Manager 호출 등은 NAT 인스턴스를 거쳐 나간다.
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

# 5. ECS Task SG: 컨테이너 포트는 ALB 를 거친 요청만 허용 (이제 ECS 는 Private Subnet 내부로 감춘다)
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Security Group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Container port from ALB Security Group"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALB 를 거친 요청만 허용
  }

  # ECR 이미지 Pull, CloudWatch 로그 전송, Secrets Manager 호출 등은 NAT 인스턴스를 거쳐 나간다.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 4. Database SG: Private EC2 의 SG 에서 오는 PostgreSQL(5432) 연결만 허용
#    - IP 대역이 아닌 "SG 를 소스로" 지정하면, EC2 가 늘어나거나 IP 가 바뀌어도 규칙을 고칠 필요가 없다.
#    - 추가로 개발자 로컬에서 DBeaver 같은 클라이언트를 통해 운영 데이터베이스에 접근할 수 있도록 Bastion 에 대해서 추가 허용
#    - DB 는 먼저 외부로 연결을 맺을 일이 없으므로 egress 규칙을 두지 않는다.
resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Security Group for PostgreSQL (RDS)"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from Private Server Security Group"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.private_server_sg.id,
      aws_security_group.ecs_task_sg.id,
    ]
  }

  ingress {
    description     = "PostgreSQL from Bastion Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Bastion SG에 대해서만 허용
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 5. ALB SG: 인터넷(0.0.0.0/0)에서 HTTP 80 [production → ECS], 8080 [develop → Private EC2] 허용
#    - egress 를 private_server_sg 로 지정하면 서로를 참조하는 순환 의존이 생기므로 VPC 대역으로 연다
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security Group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere (production listener)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP 8080 from anywhere (develop listener)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "To targets inside the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}