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
```

## 0차: AWS VPC + SG + EC2 (Private 1 + Public 2)

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
   └────────────────────────────────────────────────────────────┘
```

### 적용

테라폼 명령어를 수행하기전에는 항상 테라폼이 AWS 서비스들에 대한 CRUD 위해 AWS IAM 사용자 계정 만들어서
테라폼 명령어를 수행하는 디렉토리에서 AWS_ACCESS_KEY_ID 등의 환경변수가 설정되어있어야 한다

```bash
terraform init
terraform plan
terraform apply
```

### 정리

```bash
terraform destroy
```

## 비용 참고 (서울 리전, 대략)

t2.micro × 3 (Bastion, NAT, Private EC2). 실습 후에는 꼭 `terraform destroy` 하세요.
