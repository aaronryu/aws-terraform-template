
# 1. Bastion SG: 외부(0.0.0.0/0)로부터 SSH(22) 접속 허용
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security Group for Bastion Host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bastion-sg"
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
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name        = "nat-instance-sg"
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

  # ECR 이미지 Pull, CloudWatch 로그 전송, Secrets Manager 호출 등은 NAT 인스턴스를 거쳐 나간다.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "private-server-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 5. [2차] ECS Task SG: 컨테이너 포트는 Bastion / Private EC2 에서만 접근 가능 (ALB 없이 내부에서 확인하는 용도)
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Security Group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    # 이번 실습에서는 바로 ECS 태스크를 Public Subnet 에 두어 외부에서 바로 접근할 수 있도록 한다
    # description     = "Container port from Bastion and Private Server"
    description     = "Container port from Public IPs"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # - 만약 ECS 태스크를 Private Subnet 내 둔다면 ALB 로부터 들어올 수 있게 아래와 같은 방법으로 통로를 열어줘야한다
    # security_groups = [
    #   aws_security_group.alb_sg.id
    # ]
    # + Private Subnet 내 EC2 는 인스턴스라서 외부에서 Bastion 통해 들어올 수 있지만
    # + Private Subnet 내 ECS 는 서버리스라서 외부에서 Bastion 통해 들어올 수 없다 (FARGATE 선택 시) - 그래서 컨테이너 로그 확인은 로그 그룹 설정을 통해서만 가능
    #    - 그래서 Bastion 통한 SSH Tunneling 을 위한 22번 포트 ingress 오픈 설정은 따로 필요없다
  }

  # 만약 ECS 도 EC2 처럼 Private Network 내 위치한다면 ECR 이미지 Pull, CloudWatch 로그 전송, Secrets Manager 호출 등은 NAT 인스턴스를 거쳐 나간다.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ecs-task-sg"
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
    description = "PostgreSQL from Private Server and ECS tasks"
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
    Name        = "database-sg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
