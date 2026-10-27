
# 1. ALB: 인터넷에서 들어오는 HTTP 요청을 받는 입구 (공개 서브넷 2개 = 서로 다른 AZ 2개 이상 필수)
#   - 단일 ALB 으로 포트를 기반으로 환경을 나눈다 / 추후에는 도메인 기반으로 환경을 나눌 수 있다
#     - :80   → ECS Fargate - TG 타겟 그룹 (target_type = "ip")       (production zone)
#     - :8080 → Private EC2 - TG 타겟 그룹 (target_type = "instance") (develop zone)
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
# 2.1. (production) 대상 그룹: ECS Fargate 태스크 → target_type = "ip"
#    - Fargate 태스크는 EC2 인스턴스가 아니라 태스크마다 전용 ENI(사설 IP)를 받기 때문에 IP 로 등록된다
#    - 대상 등록/해제는 Terraform 이 아니라 ECS 서비스가 직접 한다 (태스크가 뜨면 등록, 내려가면 해제)
#        - 그래서 아래 develop 의 EC2 와 달리 aws_lb_target_group_attachment 가 없다 (등록은 ecs.tf 의 load_balancer 블록)
resource "aws_lb_target_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-tg" # 최대 32자
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # 배포 시 이전 태스크를 대상에서 빼고 진행 중인 요청을 마저 처리하도록 기다리는 시간 (기본 300초 → 배포가 5분씩 늘어진다)
  deregistration_delay = 30

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
    Name        = "${var.project_name}-${var.environment}-ecs-tg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 2. 대상 그룹: ALB 가 요청을 넘겨줄 대상 묶음 + 헬스체크
# 2.2. (develop) 대상 그룹: Private EC2 → target_type = "instance"
#    - EC2 인스턴스 ID 가 고정되어 있으므로 Terraform 이 직접 등록한다 (아래 aws_lb_target_group_attachment)
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

  # target_type 변경은 대상 그룹 "재생성" 이 필요한데,
  # 리스너가 쓰고 있는 대상 그룹은 먼저 지울 수 없어서 먼저 새것을 만들고 기존것을 삭제하기 위한 옵션
  # 만약 '기존에 연결된 타겟 그룹의 명칭' 과 '새로 연결하고자하는 타겟 그룹의 명칭' 이 다른 경우 해당 옵션 필수
  # 이번 실습에서는 기존에 사용하고있던 타겟 그룹인 -ec2-tg 를 그대로 쓰는것이라 필요 없는 옵션
  # lifecycle { create_before_destroy = true }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-tg"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 3. (develop) 대상 그룹에 Private EC2 등록
resource "aws_lb_target_group_attachment" "private_server" {
  target_group_arn = aws_lb_target_group.ec2.arn
  target_id        = var.target_instance_id
  port             = var.target_instance_port
}

# 4.1. (production) 리스너: ALB 80 포트로 들어온 요청을 ECS 대상 그룹으로 전달
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

# 4.2. (develop) 리스너: ALB 8080 포트로 들어온 요청을 EC2 대상 그룹으로 전달 (alb_sg 에서 8080 도 열어 두었다)
resource "aws_lb_listener" "develop" {
  load_balancer_arn = aws_lb.this.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2.arn
  }
}
