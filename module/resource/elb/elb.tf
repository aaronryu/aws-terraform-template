
# 1. ALB: 인터넷에서 들어오는 HTTP 요청을 받는 입구 (공개 서브넷 2개 = 서로 다른 AZ 2개 이상 필수)
resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.environment}-alb" # 최대 32자
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 2. 대상 그룹: ALB 가 요청을 넘겨줄 대상 묶음 + 헬스체크
#    - EC2 인스턴스를 대상으로 하므로 target_type = "instance" (ECS Fargate 라면 "ip")
resource "aws_lb_target_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-tg" # 최대 32자
  port        = var.target_instance_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.healthcheck_path
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-tg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 3. 대상 그룹에 Private EC2 등록
resource "aws_lb_target_group_attachment" "private_server" {
  target_group_arn = aws_lb_target_group.ec2.arn
  target_id        = var.target_instance_id
  port             = var.target_instance_port
}

# 4. 리스너: ALB 80 포트로 들어온 요청을 대상 그룹으로 전달
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2.arn
  }
}
