# aws-terraform-template

단일 서버 운영에 필요한 AWS 인프라를 Terraform 으로 단계별로 쌓아가는 실습 템플릿입니다.

| 단계    | 브랜치                       | 추가되는 내용                                                              |
| ------- | ---------------------------- | -------------------------------------------------------------------------- |
| 0차     | `aws-vpc-nat-and-bastion`    | VPC, IGW, 공개/사설 서브넷, NAT 인스턴스, Bastion, Private EC2             |
| 1차     | `aws-rds-s3`                 | DB 전용 서브넷, RDS(PostgreSQL), S3, EC2 → RDS/S3 연결(SG, IAM)            |
| **2차** | `aws-ecr-ecs-github-actions` | ECR, ECS(Fargate) 단일 컨테이너, GitHub Actions 로 이미지 빌드/배포 (OIDC) |

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

### 적용

테라폼 명령어를 수행하기전에는 항상 테라폼이 AWS 서비스들에 대한 CRUD 위해 AWS IAM 사용자 계정 만들어서
테라폼 명령어를 수행하는 디렉토리에서 AWS_ACCESS_KEY_ID 등의 환경변수가 설정되어있어야 한다

```bash
terraform init
terraform plan
terraform apply        # RDS 생성에 5~10분 걸립니다. Private EC2 는 RDS 주소가 필요해서 그 뒤에 만들어집니다.
```

> 0차까지 이미 apply 한 상태라면: Private EC2 가 **재생성**됩니다.

### 확인

terraform apply 완료 후

```bash
# 0) GitHub Secrets 에 등록 - 아래 app_config 내에는 AWS_ACCESS_KEY_ID, DATASOURCE_PASSWORD 등이 들어간다
terraform output -json app_config

# 1) Bastion 을 거쳐 Private EC2 접속 (출력된 명령을 그대로 복사)
terraform output -raw ssh_to_private_server
```

- Private EC2 외의 곳(예: Bastion)에서 5432 접속이 **막히는 것**도 직접 확인해 보세요. (SG 의 역할)

### 정리

```bash
terraform destroy      # 실습용 설정이라 RDS/S3 가 남아 있어도 삭제됩니다.
```

## 2차: ECR + ECS(Fargate) + GitHub Actions

```
 GitHub (main push)
      │  OIDC 토큰 → AWS IAM 역할(임시 자격증명)
      ▼
 GitHub Actions ──docker push──▶ ECR ◀──이미지 pull── ECS Fargate 태스크 (사설 서브넷)
      │                                                     │  │
      └── ecs update-service (새 배포) ───────────────────────┘  ├─ 5432 ▶ RDS  (Secrets Manager 의 비밀번호 주입)
                                                               └─ IAM 태스크 역할 ▶ S3
```

핵심 포인트

- **누가 무엇을 하나**: Terraform 은 _인프라_(ECR, 클러스터, 태스크 정의, 서비스)를 만들고, GitHub Actions 는 *이미지*를 만들어 올리고 재배포만 합니다. 태스크 정의는 `:latest` 이미지를 참조하므로 둘이 서로의 상태를 덮어쓰지 않습니다.
- **실행 역할 vs 태스크 역할**: 실행 역할은 ECS 가 컨테이너를 _띄울 때_(ECR pull, 로그, 시크릿 주입), 태스크 역할은 _앱이 실행 중_ AWS API(S3)를 부를 때 씁니다.
- **ALB 없음**: 단일 컨테이너를 사설 서브넷에 두고, Bastion / Private EC2 에서만 접근합니다. (공개 서비스가 필요하면 ALB 를 추가)
- **컨테이너가 받는 환경 변수**: `AWS_REGION`, `S3_BUCKET`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`(시크릿)

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
- 계정에 GitHub OIDC 공급자가 이미 있으면 `already exists` 오류가 납니다 → `github_oidc_provider_arn` 에 기존 ARN 을 지정하세요.

## 비용 참고 (서울 리전, 대략)

t2.micro × 3 (Bastion, NAT, Private EC2) + RDS `db.t3.micro` + gp3 20GB + Fargate 태스크 1개(0.5 vCPU / 1GB, 켜져 있는 시간만큼). 실습 후에는 꼭 `terraform destroy` 하세요.
