
# 최신 Amazon Linux 2023 AMI 조회
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# 1. Bastion Instance (Public Subnet)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = aws_key_pair.bastion.key_name
  associate_public_ip_address = true

  tags = {
    Name        = "bastion-instance"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 2. NAT Instance (Public Subnet)
resource "aws_instance" "nat" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.nat_instance_sg_id]
  associate_public_ip_address = true

  # NAT 인스턴스 필수 설정: Source/Destination 검사 비활성화
  source_dest_check = false

  # IP 포워딩 및 NAT 포트 포워딩 설정 (iptables) - NAT AMI 검색 못해서 이렇게 프로비저닝
  user_data = <<-EOF
              #!/bin/bash
              # 1. 커널 level IP 포워딩 활성화
              sysctl -w net.ipv4.ip_forward=1
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

              # 2. iptables 서비스 패키지 설치 및 실행
              dnf install -y iptables-services
              systemctl enable --now iptables

              # 3. FORWARD 체인 차단 해제 (ICMP(ping) 시도 시 Destination Host Prohibited 에러 해결)
              iptables -P FORWARD ACCEPT
              iptables -F FORWARD

              # 4. 기본 네트워크 인터페이스 동적 감지 및 NAT 마스커레이드 적용
              ETH=$(ip route show default | awk '/default/ {print $5}')
              iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE

              # 5. 설정 내용 파일 저장 (재부팅 후에도 유지)
              service iptables save
              EOF

  tags = {
    Name        = "nat-instance"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# + NAT 인스턴스가 생성되면 프라이빗 라우팅 테이블에 0.0.0.0/0 라우트 자동 추가
resource "aws_route" "private_nat_route" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

# 3. Private EC2 Instance (Private Subnet)
resource "aws_instance" "private_server" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = "t2.micro"
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [var.private_server_sg_id]
  key_name                    = aws_key_pair.private_server.key_name
  associate_public_ip_address = false # Private 서브넷이므로 Public IP 없음

  tags = {
    Name        = "private-server-instance"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
