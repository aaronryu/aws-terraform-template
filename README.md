# aws-terraform-template

단일 서버 운영에 필요한 AWS 인프라를 Terraform 으로 단계별로 쌓아가는 실습 템플릿입니다.

| 단계    | 브랜치                    | 추가되는 내용                                                   |
| ------- | ------------------------- | --------------------------------------------------------------- |
| 0차     | `aws-vpc-nat-and-bastion` | VPC, IGW, 공개/사설 서브넷, NAT 인스턴스, Bastion, Private EC2  |
| **1차** | `aws-rds-s3`              | DB 전용 서브넷, RDS(PostgreSQL), S3, EC2 → RDS/S3 연결(SG, IAM) |

## 디렉터리 구조

```
main.tf                       # 모듈 조립 (여기서 전체 구조를 한눈에 본다)
variables.tf / outputs.tf     # 루트 변수 / 적용 후 확인할 값
module/common/*               # VPC, 서브넷, IGW, 라우팅 테이블 (네트워크 부품)
module/network                # 네트워크 부품을 묶은 모듈
module/resource/sg            # 보안 그룹 모음
module/resource/ec2           # Bastion, NAT, Private EC2 (+ EC2 용 IAM 역할)
module/resource/rds           # [1차] DB 서브넷 그룹 + PostgreSQL
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
terraform destroy      # 실습용 설정이라 RDS 가 남아 있어도 삭제됩니다.
```

## 비용 참고 (서울 리전, 대략)

t2.micro × 3 (Bastion, NAT, Private EC2) + RDS `db.t3.micro` + gp3 20GB. 실습 후에는 꼭 `terraform destroy` 하세요.
