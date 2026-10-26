# aws-terraform-template

단일 서버 운영에 필요한 AWS 인프라를 Terraform 으로 단계별로 쌓아가는 실습 템플릿입니다.

| 단계    | 브랜치                       | 추가되는 내용                                                          |
| ------- | ---------------------------- | ---------------------------------------------------------------------- |
| 0차     | `aws-vpc-nat-and-bastion`    | VPC, IGW, 공개/사설 서브넷, NAT 인스턴스, Bastion, Private EC2         |
| 1차     | `aws-rds-s3`                 | DB 전용 서브넷, RDS(PostgreSQL), S3, EC2 → RDS/S3 연결(SG, IAM)        |
| 2차     | `aws-ecr-ecs-github-actions` | ECR, ECS(Fargate) 단일 컨테이너                                        |
| **3차** | `aws-cloudwatch-sns`         | ECS 로그(CloudWatch Logs), CPU/메모리/ERROR 로그 알람, SNS 이메일 알림 |

## 디렉터리 구조

```
main.tf                       # 모듈 조립 (여기서 전체 구조를 한눈에 본다)
variables.tf / outputs.tf     # 루트 변수 / 적용 후 확인할 값
module/common/*               # VPC, 서브넷, IGW, 라우팅 테이블 (네트워크 부품)
module/network                # 네트워크 부품을 묶은 모듈
module/resource/sg            # 보안 그룹 모음
module/resource/ec2           # Bastion, NAT, Private EC2 (+ EC2 용 IAM 역할)
module/resource/rds           # [1차] DB 서브넷 그룹 + PostgreSQL
module/resource/s3            # [1차] 서비스용 S3 버킷
module/resource/ecr           # [2차] 도커 이미지 저장소
module/resource/ecs           # [2차] 클러스터, 태스크 정의, 서비스, ECS 용 IAM 역할
module/resource/monitoring    # [3차] SNS 토픽/구독, CloudWatch 알람, 로그 메트릭 필터
                              #       (로그 그룹 자체는 module/resource/ecs/logs.tf)
terraform.tfvars.example      # 입력값 예시 (복사해서 terraform.tfvars 로)
```

## 1차: RDS(PostgreSQL) + S3

```
                      Internet
                          │
                    [ IGW ]
                          │
   ┌───────── 공개 서브넷 2개 (10.0.0.0/26, 10.0.0.64/26) ─────────┐
   │   Bastion (SSH)                     NAT 인스턴스            │
   └──────────────────────────────────────────┬─────────────────┘
                                              │ 사설 → 인터넷
   ┌───────── 사설 서브넷 2개 (10.0.0.128/26, 10.0.0.192/26) ──────┐
   │   Private EC2                                             │
   └──────────┬─────────────────────────────────────────────────┘
              │ 5432 (SG 로만 허용)
   ┌──────────▼── DB 서브넷 2개 (10.0.1.0/26, 10.0.1.64/26) ──────┐
   │   RDS PostgreSQL (ap-northeast-2a)   ※ 인터넷 경로 없음       │
   └────────────────────────────────────────────────────────────┘
```

핵심 포인트

- **보조 CIDR**: 기본 VPC CIDR(`10.0.0.0/24`)은 /26 서브넷 4개로 가득 차 있어서, `10.0.1.0/24` 를 VPC 에 추가로 연결해 DB 서브넷을 만들었습니다. (VPC 를 새로 만들 필요 없음)
- **DB 서브넷 그룹**: RDS 는 서로 다른 AZ 의 서브넷 2개 이상이 필요합니다. 실제 인스턴스는 `ap-northeast-2a` 한 곳에만 만듭니다.
- **SG → SG 허용**: DB 보안 그룹은 IP 가 아니라 *Private EC2 의 보안 그룹*에서 오는 5432 만 허용합니다.
- **사설 EC2**: 단일 컨테이너를 사설 서브넷에 두고, Bastion / Private EC2 에서만 접근합니다. (공개 서비스가 필요하면 ALB 를 추가)

### 적용

테라폼 명령어를 수행하기전에는 항상 테라폼이 AWS 서비스들에 대한 CRUD 위해 AWS IAM 사용자 계정 만들어서
테라폼 명령어를 수행하는 디렉토리에서 AWS_ACCESS_KEY_ID 등의 환경변수가 설정되어있어야 한다

```bash
terraform init
terraform plan
terraform apply        # RDS 생성에 5~10분 걸립니다. Private EC2 / EC2 가 RDS 주소가 필요한데 떠있지 않은 경우가 있을 수 있어서 방지를 위해 디펜던시를 거는것도 방법
```

> 0차까지 이미 apply 한 상태라면: Private EC2 가 **재생성**됩니다.

### 확인

terraform apply 완료 후

```bash
# 0.1) GitHub Secrets 에 수동 등록
# - 아래 github_actions_vars 내에는 ECS_CLUSTER, ECS_SERVICE, ECS_TASKDEF 등이 들어간다
# - 아래 github_actions_secrets 내에는 AWS_ACCESS_KEY_ID, DATASOURCE_PASSWORD 등이 들어간다
terraform output -json github_actions_vars
terraform output -json github_actions_secrets
```

혹은 아래 명령어에서 OWNER/REPO 각각을 여러분들의것으로 채워넣고 (예, aaronryu/aws-spring-tutorial) 한번에 원격 Github Actions 내 업로드할 수 있다

```bash
# 0.2) GitHub Secrets 에 자동 등록
brew install gh # GH (GitHub) CLI 사용을 위해 MacOS 기준 gh 설치를 해준다음
gh auth login   # gh 설치가 완료됐다면 https://github.com/settings/tokens 페이지에 들어가서 GH CLI 호출을 위한 토큰 생성하여 이 값을 Paste your authentication token: 에 입력
terraform output -json github_actions_vars | jq -r 'to_entries[] | "\(.key)\t\(.value)"' | while IFS=$'\t' read -r k v; do gh variable set "$k" --body "$v" -R OWNER/REPO; done
terraform output -json github_actions_secrets | jq -r 'to_entries[] | "\(.key)\t\(.value)"' | while IFS=$'\t' read -r k v; do printf '%s' "$v" | gh secret set "$k" -R OWNER/REPO; done
```

아래 명령어에서 OWNER/REPO 각각을 여러분들의것으로 채워넣고 (예, aaronryu/aws-spring-tutorial) 호출하면 여러분들이 저장한 Variables / Secrets 가 잘 저장되어있는지 볼 수 있다
GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens 이동하여 Permissions → Repository permissions 에 권한 추가 필요
Secrets: Read and write 그리고 Variables: Read and write 권한을 설정해주면 된다

```bash
gh secret list -R OWNER/REPO
```

- Private Subnet 내 위치한 EC2 혹은 RDS 접속하기 위해서는 Bastion 통해 SSH Tunneling 하면 되는것을 확인해보세요

```bash
# 1) Bastion 을 거쳐 Private EC2 접속 (출력된 명령을 그대로 복사)
terraform output -raw ssh_to_private_server
```

### 정리

```bash
terraform destroy      # 실습용 설정이라 RDS/S3 가 남아 있어도 삭제됩니다.
```

## 2차: ECR + ECS(Fargate) + GitHub Actions

```
 GitHub Actions ──docker push──▶ ECR ◀──이미지 pull── ECS Fargate 태스크 (공개 서브넷 Public Subnet)
      │                                                     │
      └── ecs update-service (새 배포) ───────────────────────┘
```

핵심 포인트

- **누가 무엇을 하나**: Terraform 은 _인프라_(ECR, 클러스터, 태스크 정의, 서비스)를 만들고, GitHub Actions 는 *이미지*를 만들어 올리고 재배포만 합니다. 태스크 정의는 `:latest` 이미지를 참조하므로 둘이 서로의 상태를 덮어쓰지 않습니다.
- **실행 역할 vs 태스크 역할**: 실행 역할은 ECS 가 컨테이너를 _띄울 때_(ECR pull, 로그, 시크릿 주입), 태스크 역할은 _앱이 실행 중_ AWS API(S3)를 부를 때 씁니다.
- **컨테이너가 받는 환경 변수**: `AWS_REGION`, `AWS_S3_BUCKET`, `DATASOURCE_URL`, `DATASOURCE_USERNAME`, `DATASOURCE_PASSWORD` 등 (시크릿)

### Fargate CPU/메모리

`variables.tf` 의 `ecs_task_cpu` / `ecs_task_memory` 로 조절합니다. 기본값은 512(0.5 vCPU) / 1024MiB 입니다.

- Fargate 라서 느린 것이 아니라 **태스크 정의에 적은 값만큼만** 컨테이너가 쓸 수 있습니다. 허용되는 조합은 `variables.tf` 주석 표를 참고하세요.
- 증상으로 구분: 메모리 부족이면 태스크가 `Exit code 137 (OutOfMemoryError: Container killed...)` 로 반복 종료되고, CPU 부족이면 기동이 매우 느리거나 헬스체크 타임아웃이 납니다.
- 이 템플릿은 이미지 pull 이 t2.micro **NAT 인스턴스**를 거치기 때문에, 이미지가 크면 시작이 느려질 수 있습니다.

### 적용

```bash
cp terraform.tfvars.example terraform.tfvars   # github_repository 를 본인 레포로 수정
terraform apply
terraform output                                # 워크플로우에 넣을 값 확인
```

> `apply` 직후에는 ECR 에 이미지가 없으므로 ECS 태스크가 `CannotPullContainerError` 로 계속 실패하게될텐데 이를 방지하기위해 `desired_count = 0` 값을 설정해놓아서 `apply` 직후 ECS 는 아무것도 안하고 가만히 있는다. 추후 Github Actions 통해 새로운 태스크 정의를 주입하게되면 그제서야 ECS 는 본격적인 배포 진행

### 배포

1. 애플리케이션 레포에 `examples/github-actions/deploy-to-ecs.yml` 을 `.github/workflows/deploy.yml` 로 복사하고, 상단 `env` 값을 `terraform output` 결과로 채웁니다.
2. 애플리케이션 레포의 `main` 에 push → Actions 탭에서 진행 확인 (빌드 → ECR push → ECS 배포 → 안정화 대기).

### 확인

```bash
# 태스크의 사설 IP 확인 (로컬에서, AWS CLI 자격증명 필요)
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)
TASK=$(aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK \
  --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' --output text

# Private EC2 (또는 Bastion) 안에서 호출
curl http://<태스크 사설 IP>:8080/
```

- 서비스 이벤트: `aws ecs describe-services --cluster $CLUSTER --services $SERVICE --query 'services[0].events[:5]'`
- 중지된 태스크의 이유(OOM, 이미지 pull 실패 등): ECS 콘솔 → 클러스터 → 서비스 → 작업(Stopped) 탭의 _중지된 이유_

### 이전 단계에서 바뀌는 점

- DB 보안 그룹이 _ECS 태스크 SG_ 도 허용합니다. (Private EC2 + ECS)
- `terraform destroy` 시 ECR 이미지가 남아 있어도 삭제됩니다. (`force_delete`)

## 3차: CloudWatch 로그/메트릭 + SNS 알람

```
 ECS 컨테이너 ──stdout/stderr──▶ CloudWatch Logs (/ecs/...-app)
      │                                  │ 메트릭 필터("ERROR" → AppErrorCount)
      │ AWS/ECS 메트릭 (CPU, 메모리)        ▼
      └──────────────▶ CloudWatch 알람 (임계값 초과) ──▶ SNS 토픽 ──▶ 이메일
```

핵심 포인트

- **로그**: 태스크 정의의 `logConfiguration(awslogs)` 가 컨테이너 로그를 로그 그룹으로 보냅니다. 로그 그룹을 직접 만들어 보존 기간(0 = 무제한)을 정합니다. 태스크 정의가 바뀌므로 `apply` 하면 ECS 서비스가 새 태스크로 교체됩니다.
- **메트릭**: ECS 서비스의 CPU/메모리 사용률(`AWS/ECS`)은 추가 설정 없이 1분마다 수집됩니다. 사용률은 _태스크에 할당한 값 대비 %_ 라서 2차에서 정한 `ecs_task_cpu/memory` 가 적절했는지 판단하는 근거가 됩니다.
- **알람**: 1분 평균을 3번 연속 80% 이상이면 `ALARM`, 데이터가 없으면(배포 중 등) 정상으로 취급합니다. 상태가 바뀔 때(`ALARM`, `OK`) SNS 로 알립니다.
- **로그 → 메트릭 → 알람**: 로그에 `ERROR` 가 찍힐 때마다 `AppErrorCount` 를 1씩 올리고, 1분에 1건 이상이면 알람을 울립니다.
- **SNS 이메일 구독은 수동 확인이 필요**합니다. `apply` 후 도착하는 _Subscription Confirmation_ 메일의 **Confirm subscription** 을 눌러야 알림이 옵니다.
- ECS 태스크/컨테이너 단위의 세부 메트릭(실행 중 태스크 수 등)이 필요하면 클러스터의 Container Insights 를 켜야 하지만, 유료이므로 이 템플릿에서는 켜지 않았습니다.

### 적용

```bash
# terraform.tfvars 에 alarm_email 추가
terraform apply
```

### 확인

```bash
# 1) 로그: 실시간으로 보기 (AWS CLI v2)
aws logs tail $(terraform output -raw ecs_log_group_name) --follow

# 2) 알람 → SNS → 메일 경로 테스트: 실제 부하 없이 알람 상태를 강제로 바꿔 본다
aws cloudwatch set-alarm-state --alarm-name $(terraform output -raw cpu_alarm_name) \
  --state-value ALARM --state-reason "manual test"
#  → 메일이 오고, 잠시 뒤 실제 상태(OK)로 돌아오면서 OK 메일이 한 번 더 온다

# 3) ERROR 로그 → 메트릭 → 알람 경로 테스트 (앱 코드를 고치지 않고 로그 한 줄을 직접 넣는다)
LOG_GROUP=$(terraform output -raw ecs_log_group_name)
aws logs create-log-stream --log-group-name $LOG_GROUP --log-stream-name manual-test
aws logs put-log-events --log-group-name $LOG_GROUP --log-stream-name manual-test \
  --log-events timestamp=$(($(date +%s)*1000)),message="ERROR manual test"
#  → 1~2분 안에 error 알람이 울리고 메일이 온다
```

- 진짜 CPU 알람을 보고 싶다면 `main.tf` 의 `module "monitoring"` 에 `cpu_threshold_percent = 1` 처럼 임계값을 낮춰서 `apply` 해 보세요.
- CloudWatch 콘솔 → 메트릭 → `ECS` → `ClusterName, ServiceName` 에서 `CPUUtilization`, `MemoryUtilization` 의 *평균*과 *최대*를 같이 보면, 태스크 크기가 부족한지 넉넉한지 판단할 수 있습니다.

## 비용 참고 (서울 리전, 대략)

t2.micro × 3 (Bastion, NAT, Private EC2) + RDS `db.t3.micro` + gp3 20GB + Fargate 태스크 1개(0.5 vCPU / 1GB, 켜져 있는 시간만큼) + CloudWatch(로그 수집/보관, 알람 3개). 실습 후에는 꼭 `terraform destroy` 하세요.
