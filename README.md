# aws-terraform-template

단일 서버 운영에 필요한 AWS 인프라를 Terraform 으로 단계별로 쌓아가는 실습 템플릿입니다.

| 단계 | 브랜치                          | 추가되는 내용                                                                         |
| ---- | ------------------------------- | ------------------------------------------------------------------------------------- |
| 0차  | `base/aws-vpc-nat-and-bastion`  | VPC, IGW, 공개/사설 서브넷, NAT 인스턴스, Bastion, Private EC2                        |
| 1차  | `add-on-base/1-aws-elb`         | ELB(L7-ALB) 연결하여 사설 서브넷 내 EC2 외부로 서비스 서빙                            |
| 2차  | `add-on-base/2-aws-rds-and-s3`  | 데이터베이스 서버를 위한 보조 CIDR + DB 전용 서브넷 2개, RDS(PostgreSQL)              |
| 3차  | `add-on-base/2-aws-rds-and-s3`  | S3 버킷(공개 읽기, CORS, 암호화) + 스프링 앱용 IAM 사용자/액세스 키                   |
| 4차  | `add-on-base/3-aws-ecr-and-ecs` | ECR(이미지 저장소) + ECS Fargate(클러스터, 태스크 정의, 서비스) + GitHub Actions 배포 |

## 디렉터리 구조

```
main.tf                       # 모듈 조립 (여기서 전체 구조를 한눈에 본다)
variables.tf / outputs.tf     # 루트 변수 / 적용 후 확인할 값
module/common/*               # VPC, 서브넷, IGW, 라우팅 테이블 (네트워크 부품)
module/network                # 네트워크 부품을 묶은 모듈
module/resource/sg            # 보안 그룹 모음
module/resource/ec2           # Bastion, NAT, Private EC2
module/resource/elb           # [1차] ALB, 대상 그룹, 리스너
module/resource/rds           # [2차] DB 서브넷 그룹 + PostgreSQL
module/resource/s3            # [3차] S3 버킷 + 스프링 앱 사용자에게 붙이는 버킷 권한
module/resource/ecr           # [4차] ECR 저장소 + 오래된 이미지 정리 라이프사이클
module/resource/ecs           # [4차] ECS 클러스터, 플레이스홀더 태스크 정의, 서비스, 실행 역할
```

## 0차: AWS VPC + SG + EC2 (Private 1 + Public 2)

```
   개발자 PC                    Internet
       │                            ▲
       │ SSH 22                     │
       │                         [ IGW ]
       │                            │
 ┌─────┼────────────────────────────┼──────── VPC 10.0.0.0/24 ────────────────┐
 │     │  ap-northeast-2a           │        ap-northeast-2b                  │
 │ ┌───▼─ 공개 서브넷 10.0.0.0/26 ──┼───┐  ┌─ 공개 서브넷 10.0.0.64/26 ─────┐ │
 │ │ Bastion              NAT 인스턴스  │  │ (비어 있음)                    │ │
 │ │ (bastion-sg)      (nat-instance-sg)│  │                                │ │
 │ └───┼────────────────────────────▲───┘  └────────────────────────────────┘ │
 │     │ SSH 22                     │ 0.0.0.0/0 (사설 → 인터넷)               │
 │ ┌───▼────────────────────────────┼───┐  ┌────────────────────────────────┐ │
 │ │ Private EC2 (private-server-sg)    │  │ (비어 있음)                    │ │
 │ └───── 사설 서브넷 10.0.0.128/26 ────┘  └─ 사설 서브넷 10.0.0.192/26 ────┘ │
 └────────────────────────────────────────────────────────────────────────────┘
```

- **Bastion**: 개발자 IP(와 EC2 Instance Connect)에서 오는 SSH 22 만 허용합니다. 사설 서브넷으로 들어가는 유일한 입구입니다.
- **NAT 인스턴스**: 사설 서브넷에서 나가는 트래픽(`dnf`, 외부 API 등)을 대신 인터넷으로 내보냅니다. 들어오는 연결은 받지 않습니다.
- **Private EC2**: 공인 IP 가 없고, Bastion SG 에서 오는 SSH 22 만 허용합니다.
- 서브넷을 AZ 2개에 나눠 둔 것은 1차의 ALB(최소 2개 AZ 필요)와 이후 RDS 서브넷 그룹을 위한 준비입니다.

### 적용

테라폼 명령어를 수행하기전에는 항상 테라폼이 AWS 서비스들에 대한 CRUD 위해
AWS IAM 사용자 계정 만들어서 테라폼 명령어를 수행하는 디렉토리에서 AWS_ACCESS_KEY_ID 등의 환경변수가 설정되어있어야 한다

```bash
terraform init
terraform plan
terraform apply
```

### 확인

첫번째 터미널에서 수행

```bash
eval "$(terraform output -raw ssh_tunnel_to_private_server)"
```

```bash
# 위 명령어는 실제 아래와 똑같이 수행되는것 (아래 명령어에 채워진 IP 주소는 예시)
ssh -i local-to-bastion.pem -N -L 33322:10.0.0.138:22 ec2-user@15.165.15.132
```

두번째 터미널에서 수행

```bash
eval "$(terraform output -raw ssh_to_private_server)"
```

```bash
# 위 명령어는 실제 아래와 똑같이 수행되는것 (아래 명령어에 채워진 IP 주소는 예시)
ssh -i local-to-private.pem -p 33322 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@localhost
```

실제 Private Subnet 내 인스턴스에 접속이 완료되었다면, 아래 명령어를 수행해서 NAT 인스턴스가 잘 연결되어있나 확인

```bash
ping google.com
```

### 정리

```bash
terraform destroy
```

## 1차: ELB(ALB) + Private EC2

```
                         사용자 브라우저 / curl
                                  │ HTTP 80  (http://<alb_dns_name>)
                                  ▼
 ┌─ VPC 10.0.0.0/24 ──────────────┼──────────────────────────────────────────┐
 │                             [ IGW ]                                        │
 │                                │                                           │
 │      ap-northeast-2a           │             ap-northeast-2b               │
 │ ┌─ 공개 서브넷 10.0.0.0/26 ──────┼───┐ ┌─ 공개 서브넷 10.0.0.64/26 ───────┐   │
 │ │                     ┌─────────▼───┴─┴─────────────────────┐          │   │
 │ │ Bastion   NAT       │  ALB (alb-sg)   리스너 HTTP:80        │          │   │
 │ │                     │  AZ 마다 노드가 하나씩 뜬다              │          │   │
 │ │                     └─────────┬───┬─┬─────────────────────┘          │   │
 │ └───────────────────────────────┼───┘ └──────────────────────────────────┘   │
 │                                 │ 대상 그룹 (instance, :8080)                  │
 │                                 │ + 헬스체크 GET / → 200                       │
 │ ┌─ 사설 서브넷 10.0.0.128/26 ──────▼──┐ ┌─ 사설 서브넷 10.0.0.192/26 ┐          │
 │ │ Private EC2 :8080                  │ │        (비어 있음)          │          │
 │ │ (private-server-sg: alb-sg → 8080) │ │                            │          │
 │ └────────────────────────────────────┘ └────────────────────────────┘          │
 └──────────────────────────────────────────────────────────────────────────────┘
```

- **ALB 는 공개 서브넷, 서버는 사설 서브넷**: 인터넷에서 보이는 것은 ALB 뿐이고, Private EC2 는 여전히 공인 IP 없이 사설 서브넷에 있습니다.
- **ALB 는 서로 다른 AZ 의 서브넷이 최소 2개 필요**합니다. 그래서 0차에서 공개 서브넷을 2a / 2b 에 하나씩 만들어 두었습니다.
- **SG → SG 허용**: `private-server-sg` 는 IP 가 아니라 _ALB 의 SG(`alb-sg`)_ 에서 오는 `target_instance_port`(기본 8080) 만 허용합니다. ALB 를 거치지 않은 요청은 서버까지 오지 못합니다.
- **리소스 4개**: `aws_lb`(입구) → `aws_lb_listener`(80 으로 받은 요청을) → `aws_lb_target_group`(어디로 보낼지 + 헬스체크) ← `aws_lb_target_group_attachment`(Private EC2 등록)
- EC2 를 대상으로 하므로 대상 그룹의 `target_type` 은 `instance` 입니다. (ECS Fargate 를 붙일 때는 `ip`)

### 적용

```bash
terraform apply
```

apply 직후에는 Private EC2 에 8080 으로 응답하는 서버가 없어서 대상 그룹이 `unhealthy` 이고, ALB 는 `502 Bad Gateway` 를 돌려줍니다. 0차의 방법으로 Private EC2 에 접속해서 테스트용 웹 서버를 띄웁니다.

```bash
# Private EC2 안에서 (NAT 인스턴스 덕분에 dnf 가 동작한다)
echo "hello from private ec2" > index.html
nohup python3 -m http.server 8080 > /dev/null 2>&1 &
```

### 확인

```bash
# 1) 대상 그룹 헬스체크 상태: healthy 가 될 때까지 30초 간격으로 2번 성공해야 한다 (약 1분)
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw ec2_target_group_arn)

# 2) ALB 를 통해 호출 (ALB 생성 직후에는 DNS 전파에 1~2분 걸릴 수 있다)
curl "http://$(terraform output -raw alb_dns_name)"
```

- `unhealthy` 일 때 `Reason` 으로 원인을 구분합니다. `Target.Timeout` 이면 SG 또는 서버 미기동, `Target.ResponseCodeMismatch` 면 헬스체크 경로가 200 을 돌려주지 않는 것입니다.

### 정리

```bash
terraform destroy
```

## 2차: RDS(PostgreSQL)

```
                        사용자 (브라우저 / curl)
                                 │ HTTP 80  http://<alb_dns_name>
                                 │
                              [ IGW ]
                                 │
 ┌───────────────────────────────┼─ VPC 10.0.0.0/24 + 보조 CIDR 10.1.0.0/24 ──┐
 │  ap-northeast-2a                          ap-northeast-2b                  │
 │ ┌─ 공개 서브넷 10.0.0.0/26 ───┼──────┐  ┌─ 공개 서브넷 10.0.0.64/26 ─────┐ │
 │ │              ┌──────────────▼──────────────────────────┐               │ │
 │ │              │ ALB (alb-sg)   리스너 HTTP:80           │               │ │
 │ │ Bastion      │ AZ 마다 노드가 1개씩 (2a, 2b)           │               │ │
 │ │ NAT          │                                         │               │ │
 │ │              └──────────────┬──────────────────────────┘               │ │
 │ └─────────────────────────────┼──────┘  └────────────────────────────────┘ │
 │                               │ 대상 그룹 (instance, :8080)                │
 │                               │                                            │
 │ ┌─────────────────────────────▼──────┐  ┌────────────────────────────────┐ │
 │ │ Private EC2 :8080                  │  │ (비어 있음)                    │ │
 │ │ (private-server-sg)                │  │                                │ │
 │ └────┬─ 사설 서브넷 10.0.0.128/26 ───┘  └─ 사설 서브넷 10.0.0.192/26 ────┘ │
 │      │ 5432 (database-sg 가 허용)                                          │
 │      │                                                                     │
 │ ┌────▼───────────────────────────────┐  ┌────────────────────────────────┐ │
 │ │ RDS PostgreSQL 16                  │  │ (비어 있음)                    │ │
 │ │ (database-sg)                      │  │ Multi-AZ 를 켜면 대기 DB 자리  │ │
 │ │ db.t3.micro, 단일 AZ               │  │                                │ │
 │ └─ DB 서브넷 10.1.0.0/26 ────────────┘  └─ DB 서브넷 10.1.0.64/26 ───────┘ │
 │ └────────────── DB 서브넷 그룹 (서로 다른 AZ 2개 필수) ──────────────────┘ │
 │  DB 라우팅 테이블: local 경로만 (0.0.0.0/0 없음 = 인터넷 왕복 불가)        │
 └────────────────────────────────────────────────────────────────────────────┘
```

핵심 포인트

- **보조 CIDR**: 기본 VPC CIDR(`10.0.0.0/24`)은 /26 서브넷 4개로 이미 가득 차 있어서, `10.1.0.0/24` 를 VPC 에 추가로 연결해 DB 서브넷 2개(`10.1.0.0/26`, `10.1.0.64/26`)를 만들었습니다. (VPC 를 새로 만들 필요 없음)
  - 바로 옆 대역인 `10.0.1.0/24` 는 쓸 수 없습니다. VPC 에 `10.0.0.0/15` 범위의 CIDR 이 있으면 `10.0.0.0/16` 범위는 보조 CIDR 로 붙일 수 없다는 [AWS 제한](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html#add-cidr-block-restrictions) 때문에 `InvalidVpc.Range` 오류가 납니다.
- **DB 서브넷 그룹**: RDS 는 `multi_az = false` 여도 서로 다른 AZ 의 서브넷이 2개 이상 들어 있는 서브넷 그룹을 요구합니다. 실제 인스턴스는 `ap-northeast-2a` 한 곳에만 만듭니다.
- **인터넷 경로 없음**: DB 서브넷은 local 경로만 있는 전용 라우팅 테이블을 씁니다. `publicly_accessible = false` 와 함께, RDS 는 VPC 안에서만 접근할 수 있습니다.
- **SG → SG 허용**: `database-sg` 는 IP 가 아니라 `private-server-sg` 와 `bastion-sg` 에서 오는 5432 만 허용합니다. ALB 나 인터넷에서는 닿지 않습니다.
- **비밀번호**: `random_password` 로 만들어 RDS 에 넣고, `terraform output` 으로만 꺼냅니다. (state 파일에 평문으로 남으므로 state 는 Git 에 올리지 않는다)

### 적용

주의 : RDS 생성에 5~10분 걸린다 - 서버 구동 이후 문제가 생겼을때 첫 상태로 복귀하기 위한 백업본을 초기 서버 생성 시 만들기 때문에 오래 걸리는것

```bash
terraform apply
```

### 확인

로컬 PC 의 DB 클라이언트(DBeaver 등)에서 Bastion 을 거쳐 RDS 에 접속합니다.

```
 개발자 PC (DBeaver)                 공개 서브넷               DB 서브넷
 localhost:25432 ──── SSH 터널 ────▶ Bastion ──── 5432 ────▶ RDS
```

첫번째 터미널에서 터널을 연다 (열려 있는 동안 출력 없이 대기)

```bash
eval "$(terraform output -raw ssh_tunnel_to_rds)"
```

```bash
# 위 명령어는 실제 아래와 똑같이 수행되는것 (아래 명령어에 채워진 IP 주소는 예시)
ssh -i local-to-bastion.pem -N -L 25432:example.ap-northeast-2.rds.amazonaws.com:5432 ec2-user@15.165.15.132
```

DBeaver 에서 Host `localhost`, Port `25432`, Database `appdb`, Username `appuser` 로 접속합니다. 접속을 위한 비밀번호 포함 정보는 아래로 확인합니다.

```bash
terraform output -json github_actions_secrets
```

- Private EC2 에서 직접 붙어 보고 싶다면, 0차의 방법으로 접속한 뒤 `psql -h $(terraform output -raw rds_dns_name) -U appuser -d appdb` 로 접속합니다. (`sudo dnf install -y postgresql16` 필요)

### 정리

```bash
terraform destroy      # 실습용 설정이라 skip_final_snapshot = true, 스냅샷 없이 삭제됩니다.
```

## 3차: S3 + 스프링 앱용 IAM ← 파일 CRUD 실습 프로젝트 배포 가능

```
[브라우저]  ── GET 객체 (인증 없음) ─────────▶  S3 버킷   ← 버킷 정책 public_read (GetObject 만 공개)
[브라우저]  ── fetch / XHR ───────────────▶  S3 버킷   ← CORS (허용 Origin: ALB 도메인, localhost)
[스프링 앱] ── AWS SDK + 앱 사용자 액세스 키 ─▶  S3 버킷   ← IAM 사용자 정책 (이 버킷만 List/Get/Put/Delete)
[스프링 앱] ── Presigned URL 발급 ─────────▶ [브라우저] ── 그 URL 로 직접 업로드/다운로드 ─▶ S3 버킷
```

핵심 포인트

- **누가 / 무엇을 분리**: 스프링 앱용 IAM 사용자와 액세스 키는 `module/resource/ec2/iam.tf`(누가), 이 버킷에 대한 권한(`aws_iam_user_policy`)은 `module/resource/s3/iam.tf`(무엇을)에 둡니다. 권한은 **이 버킷 하나**에 대해서만 List / Get / Put / Delete 로 좁혀 두었습니다.
- **공개 읽기는 버킷 정책으로만**: `public_read` 버킷 정책이 누구에게나 `GetObject` 만 허용합니다. 목록 조회, 업로드, 삭제는 공개되지 않습니다. ACL 로 공개하는 경로는 Public Access Block 으로 계속 막아 둡니다.
- **CORS 는 접근 제어가 아닙니다**: 허용한 Origin 의 웹 페이지 JavaScript 가 버킷을 호출해도 된다고 _브라우저에게_ 알려 줄 뿐입니다. ALB 도메인(`http(s)://<alb_dns_name>`)과 `cors_allowed_origins` 가 자동으로 들어갑니다. 브라우저에서 Presigned URL 로 직접 업로드하려면 `cors_allowed_methods` 에 `PUT` 을 추가합니다.
- **버킷 이름**: 계정·리전 네임스페이스(`account-regional`)를 써서 `<project>-<env>-<계정ID>-<리전>-an` 형태로 만들어 전 세계 이름 충돌을 피합니다.
- **인스턴스 프로파일로 바꾸려면**: `module/resource/ec2/iam.tf` 의 [방식 B] 주석을 참고합니다. 액세스 키 없이 IMDS 의 임시 자격증명을 쓰며, Presigned URL 도 그대로 동작합니다. (단, URL 유효기간이 임시 자격증명 만료 시간, 보통 몇 시간을 넘지 못함)

### 적용

```bash
terraform apply
```

### 확인

```bash
# 1) 스프링 앱에 넣을 값 확인 (GitHub Variables / Secrets 에 등록)
terraform output -json github_actions_vars      # AWS_S3_BUCKET 등
terraform output -json github_actions_secrets   # APP_AWS_ACCESS_KEY_ID / APP_AWS_SECRET_ACCESS_KEY 등

# 2) 앱 사용자 키로 업로드 + 권한 범위 확인 (로컬에서, jq 필요: brew install jq)
#    - ( ) 서브셸 안에서만 앱 사용자 키로 바꾼다 → 괄호가 끝나면 원래 셸(direnv 등으로 설정한 Terraform 용 키)은 그대로
BUCKET=$(terraform output -json github_actions_vars | jq -r .AWS_S3_BUCKET)
(
  export AWS_ACCESS_KEY_ID=$(terraform output -json github_actions_secrets | jq -r .APP_AWS_ACCESS_KEY_ID)
  export AWS_SECRET_ACCESS_KEY=$(terraform output -json github_actions_secrets | jq -r .APP_AWS_SECRET_ACCESS_KEY)
  echo "hello s3" > hello.txt
  aws s3 cp hello.txt "s3://$BUCKET/hello.txt"   # 이 버킷에는 업로드 가능 → 성공
  aws s3 ls                                       # 전체 버킷 목록 조회는 권한 밖 → AccessDenied
)

# 3) 공개 URL 로 읽기: 버킷 정책(public_read) 덕분에 인증 없이 읽힌다
curl "https://$BUCKET.s3.ap-northeast-2.amazonaws.com/hello.txt"
unset BUCKET
```

- `export` 를 서브셸 `( )` 없이 바로 실행하면 그 터미널의 키가 앱 사용자 키로 덮어써져서, 이후 `terraform plan` 이 AccessDenied 로 실패합니다. 그렇게 됐다면 `direnv reload` (또는 키를 다시 설정) 하세요.

이제 비로소 파일 CRUD 실습 프로젝트 배포가 가능해졌다 RDS, S3 모두 사용가능해졌기 때문

- 과거 Github Actions 통해 스프링 배포했던것을 활용하여 직접 Github Actions 워크플로우를 작성해보자
  - 예시 코드는 제공되지 않는다 : 아직은 ECR 사용하지 않고 Docker Hub 사용하여 업로드 후 배포
    - 우리는 지금 이쯤에서 배포 실습하지않고 -> 다음 ECR, ECS 실습 후 그걸로 배포할것이다

### 정리

```bash
terraform destroy      # 실습용 설정이라 force_destroy = true, 객체가 남아 있어도 버킷이 삭제됩니다.
```

## 4차: ECR + ECS(Fargate) ← GitHub Actions 로 스프링 앱 배포

```
 GitHub Actions (스프링 프로젝트 push 시)
   ① ./gradlew clean build → docker build
   ② docker push ─────────────────────────────▶ ECR  <project>-<env>-app  (:커밋SHA 7자리, :latest)
   ③ aws ecs register-task-definition            (같은 family 로 새 개정본이 쌓인다)
   ④ aws ecs update-service --desired-count 1 ─▶ ECS 클러스터 / 서비스
                                                      │ 태스크 1개 기동 (Fargate)
                                                      ▼
 ┌─ 공개 서브넷 (10.0.0.0/26, 10.0.0.64/26) ───────────────────────────────────┐
 │  Fargate 태스크 :8080  (ecs-task-sg, 공인 IP 할당)                          │
 │    - 실행 역할로 ECR 이미지 Pull (공인 IP → IGW 로 직접 나간다, NAT 안 씀)  │
 └──────────────┬──────────────────────────────────────────────────────────────┘
                │ 5432 (database-sg 가 ecs-task-sg 를 허용)        S3 ← 앱 사용자 액세스 키
                ▼
              RDS PostgreSQL

 개발자 PC ── http://<태스크 공인 IP>:8080 ──▶ Fargate 태스크   (아직 ALB 연결 전이라 공인 IP 로 직접 확인)
```

핵심 포인트

- **Terraform 은 "배포 받을 자리" 까지만 만든다**: 클러스터, 서비스, 실행 역할, 그리고 `:placeholder` 이미지를 가리키는 첫 태스크 정의만 만들고 서비스는 `desired_count = 0` 입니다. 실제 이미지와 환경 변수가 담긴 태스크 정의는 GitHub Actions 가 배포할 때마다 새 개정본으로 등록합니다.
- **`ignore_changes = [task_definition, desired_count]`**: 배포 후 다시 `terraform apply` 해도 GitHub Actions 가 올린 개정본과 태스크 개수를 플레이스홀더로 되돌리지 않습니다.
- **실행 역할(execution role)**: ECS 가 컨테이너를 "띄우기 위해" ECR 이미지 Pull, CloudWatch 로그 전송에 쓰는 권한입니다. (`AmazonECSTaskExecutionRolePolicy`) 스프링 앱의 S3 접근은 3차의 앱 사용자 액세스 키를 환경 변수로 넣어 처리합니다.
- **circuit breaker**: 새 태스크가 계속 기동에 실패하면 배포를 FAILED 로 멈춰서, 실패하는 컨테이너를 무한히 재시도하며 비용이 나가는 것을 막습니다.
- **ECR 라이프사이클**: 태그 없는 이미지는 1일 뒤, 태그 이미지는 최근 10개만 남기고 지웁니다. (= 최근 10번 배포까지 롤백 가능)
- **CPU / 메모리**: 기본 `512 / 1024` (0.5 vCPU / 1GB). JVM 은 이보다 작으면 느리거나 OOM(종료 코드 137) 으로 죽기 쉽습니다. 허용 조합은 `variables.tf` 주석 참고.
- **아직 ALB 를 붙이지 않았다**: 태스크를 공개 서브넷에 두고 공인 IP 를 받아 `ecs-task-sg` 로 8080 을 열어 둔 상태입니다. 동작 확인용 구성이며, 현업에서는 태스크를 사설 서브넷에 숨기고 ALB 대상 그룹(`target_type = "ip"`)에 연결합니다.

### 적용

```bash
terraform apply
```

### 배포

스프링 프로젝트 [aaronryu/aws-spring-tutorial](https://github.com/aaronryu/aws-spring-tutorial/tree/aws/ecr-ecs/upload-and-deploy) 의 `aws/ecr-ecs/upload-and-deploy` 브랜치를 GitHub Actions 로 배포합니다. (`.github/workflows/ecr-push.yml` + `ecs-task-def.json`)

1. 스프링 프로젝트를 본인 GitHub 로 Fork / 복사한 뒤, 이 Terraform 의 출력값을 **Settings > Secrets and variables > Actions** 에 등록합니다.

   ```bash
   # 아래 REPO 를 본인 스프링 프로젝트 저장소로 바꾼다 (gh CLI 필요: brew install gh && gh auth login)
   REPO=<본인 GitHub 계정>/aws-spring-tutorial

   # Variables (비밀 아님): AWS_REGION, ECR_REPOSITORY, ECS_CLUSTER, ECS_SERVICE, ECS_TASKDEF ...
   terraform output -json github_actions_vars \
     | jq -r 'to_entries[] | "\(.key) \(.value)"' \
     | while read -r k v; do gh variable set "$k" --body "$v" -R "$REPO"; done

   # Secrets (비밀): DATASOURCE_URL / USERNAME / PASSWORD, APP_AWS_ACCESS_KEY_ID / APP_AWS_SECRET_ACCESS_KEY
   terraform output -json github_actions_secrets \
     | jq -r 'to_entries[] | "\(.key) \(.value)"' \
     | while read -r k v; do gh secret set "$k" --body "$v" -R "$REPO"; done
   unset REPO
   ```

   - 워크플로우가 ECR Push / ECS 배포에 쓰는 `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` 는 Terraform 출력에 없습니다. 배포 권한이 있는 IAM 사용자의 키를 GitHub 페이지에서 직접 Secrets 에 추가합니다.
   - 화면에 출력된 `-json` 결과를 복사해 붙여 넣지 마세요. 비밀번호의 `&` 같은 문자가 `&` 으로 이스케이프되어 있습니다. 위처럼 `jq -r` 를 거치면 원래 문자로 풀려서 등록됩니다.

2. `aws/ecr-ecs/upload-and-deploy` 브랜치에 push 하면 (또는 Actions 탭에서 Re-run) 빌드 → ECR Push → 태스크 정의 등록 → 서비스 업데이트 → 안정화 대기까지 진행됩니다.

### 확인

배포가 끝나면 태스크의 공인 IP 를 찾아 직접 접속합니다.

```bash
# 1) 서비스에서 실행 중인 태스크 → 그 태스크의 네트워크 인터페이스(ENI) → 공인 IP 순으로 찾는다
CLUSTER=$(terraform output -json github_actions_vars | jq -r .ECS_CLUSTER)
SERVICE=$(terraform output -json github_actions_vars | jq -r .ECS_SERVICE)
TASK=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --query 'taskArns[0]' --output text)
ENI=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$TASK" --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)
IP=$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI" --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
echo "$IP"

# 2) 헬스체크: actuator health 는 DB 연결까지 확인하므로 {"status":"UP"} 이면 RDS 연결도 정상
curl "http://$IP:8080/actuator/health"
```

브라우저에서 `http://<위에서 찾은 IP>:8080/files/page` 에 들어가면 파일 업로드 / 목록 / 삭제 화면이 뜹니다. 파일을 올려 보면 RDS(파일 메타데이터)와 S3(파일 본문)가 실제로 함께 동작하는 것을 확인할 수 있습니다.

![성공적으로 스프링 어플리케이션이 퍼블릭 ECS 내 배포되었을때](ecs-spring-succeed.png)

```bash
unset CLUSTER SERVICE TASK ENI IP
```

- 태스크 공인 IP 는 **배포할 때마다 바뀝니다.** (새 태스크 = 새 ENI) 재배포했다면 위 1) 을 다시 실행하세요. 고정 주소가 필요한 이유이고, 다음 단계에서 ALB 를 붙이는 이유입니다.
- 배포가 FAILED 로 끝나거나 태스크가 계속 죽는다면 멈춘 이유를 확인합니다.

  ```bash
  CLUSTER=$(terraform output -json github_actions_vars | jq -r .ECS_CLUSTER)
  STOPPED=$(aws ecs list-tasks --cluster "$CLUSTER" --desired-status STOPPED --query 'taskArns[0]' --output text)
  aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$STOPPED" \
    --query 'tasks[0].{reason:stoppedReason,exit:containers[0].exitCode,detail:containers[0].reason}'
  unset CLUSTER STOPPED
  ```

  - `CannotPullContainerError`: ECR 저장소 이름 / 이미지 태그, 또는 태스크의 인터넷 경로(공인 IP) 확인
  - 종료 코드 `1`: 스프링 앱 기동 실패 (DB 접속 정보, 프로파일 설정 등) / `137`: 메모리 부족

### 정리

```bash
terraform destroy      # 실습용 설정이라 ECR force_delete = true, 이미지가 남아 있어도 저장소가 삭제됩니다.
```

## 비용 참고 (서울 리전, 대략)

t3.micro × 3 (Bastion, NAT, Private EC2) + [1차] ALB 1개(시간당 요금 + LCU 사용량) + [2차] RDS `db.t3.micro` + gp3 20GB + [3차] S3 (저장 용량 + 요청 수, 실습 수준이면 거의 0) + [4차] Fargate 태스크 0.5 vCPU / 1GB (실행 중인 시간만큼) + 태스크 공인 IPv4 + ECR 저장 용량. 실습 후에는 꼭 `terraform destroy` 하세요.
