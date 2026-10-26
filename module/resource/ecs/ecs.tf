
# 1. 클러스터: 서비스/태스크를 묶는 논리적 단위 (Fargate 는 서버를 직접 관리하지 않는다)
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 2. 태스크 정의 (플레이스홀더 - 값들이 제대로 채워지지 않은 가장 기본의 태스크 정의)
#    - 실제 배포용 태스크 정의(이미지, 환경 변수, CPU/메모리)는
#        - Github Actions 가 배포할 때마다 스프링 프로젝트 내 ecs-task-def.json 템플릿 파일 기반으로 새 개정본 ecs-task-def.rendered.json 을 만든 뒤 등록한다.
#    - 그런데 ECS "서비스" 를 완전히 처음 만들 때 태스크 정의가 반드시 하나 필요한데 채울만한 변수 정보들은 따로 없기에 이 플레이스홀더가 존재한다.
#    - 이 플레이스홀더 태스크 정의는 실제 서비스를 띄우기 위한게 아니라 첫 ECS 정의를 위해 존재하는 더미 설정과 같아서
#        - 아래 서비스가 desired_count = 0 으로 해놓았고, 따라서 이 정의로는 컨테이너가 절대 단 한개도 뜨지 않는다.
#        - 만약 desired_count = 1 이상이었다면, 계속 배포를 시도하고 실패하고를 반복하면서 AWS 비용이 부과될 것
#    - family 이름은 Github Actions 에서 사용하는 taskdef JSON 템플릿 내 family 명과 반드시 같아야 한다. (같은 family 의 개정본으로 쌓인다)
data "aws_region" "current" {}
locals { container_name = "app" }

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-app-taskdef"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # 태스크마다 전용 ENI(사설 IP)를 받는다
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name         = local.container_name
      image        = "${var.ecr_repository_url}:placeholder" # 실제 존재하지않는 이미지 -> 실제 이미지는 :latest 태그명
      essential    = true
      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          # "awslogs-create-group"  = true # 따로 이 옵션이 필요없는것이 같은 디렉토리 내 log.tf 파일을 통해 로그 그룹 생성 후 그 그룹명을 그대로 넣었기 때문
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-taskdef"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}

# 3. 서비스: 배포를 받을 "준비 상태" 로만 만들어 둔다. (태스크 0개)
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  # 새 태스크가 계속 기동에 실패하면 배포를 FAILED 로 멈추는 설정
  # - 어자피 재배포해도 실패하는 이미지 / 컨테이너인데 지속적으로 불필요한 재배포에 따른 비용낭비를 방지하기 위해 본 설정
  #    - 직전 성공 배포로 되돌리는 설정은 껐다 (플레이스홀더 태스크 정의가 :placeholder 존재하지 않는 태그의 도커 이미지를 사용하기때문)
  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }

  network_configuration {
    subnets          = var.public_subnet_ids # 추후 Private Subnet 사용하여 ALB 붙이는것이 좋다 - 좀 더 현업에 맞는 설계
    security_groups  = [var.ecs_task_sg_id]
    assign_public_ip = true # 만약 Private Subnet 사설 서브넷 사용 시 false 으로 변환: 인터넷으로 나갈 때 NAT 인스턴스 사용하도록
  }

  # 이 두 값은 이제 Github Actions 통한 자동 CI/CD 배포 시 자체적으로 렌더링한 JSON 태스크 정의로 바꾸는 값이기때문에
  #    - 아래의 값들은 Github Actions 배포 시마다 매번 값이 바뀌게 된다.
  #    - 그 후 terraform apply 재실행하면 테라폼이 자신의 플레이스홀더의 무의미한 값들로 다시 덮어쓰기해서 기존 배포본이 모두 날라가버린다
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  # Excecution Role 실행 역할 정책이 붙은 뒤에서야 그것을 확인한 뒤 서비스를 만들도록 강제한다
  depends_on = [aws_iam_role_policy_attachment.execution]

  tags = {
    Name        = "${var.project_name}-${var.environment}-service"
    ManagedBy   = "aaron"
    Environment = var.environment
  }
}
