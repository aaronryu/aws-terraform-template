# aws-terraform-template

단일 서버 운영에 필요한 AWS 인프라를 Terraform 으로 단계별로 쌓아가는 실습 템플릿입니다.

| 단계 | 브랜치                         | 추가되는 내용                                                  |
| ---- | ------------------------------ | -------------------------------------------------------------- |
| 0차  | `base/aws-vpc-nat-and-bastion` | VPC, IGW, 공개/사설 서브넷, NAT 인스턴스, Bastion, Private EC2 |
| 1차  | `add-on-base/1-aws-elb`        | ELB(L7-ALB) 연결하여 사설 서브넷 내 EC2 외부로 서비스 서빙     |

## 디렉터리 구조

```
main.tf                       # 모듈 조립 (여기서 전체 구조를 한눈에 본다)
variables.tf / outputs.tf     # 루트 변수 / 적용 후 확인할 값
module/common/*               # VPC, 서브넷, IGW, 라우팅 테이블 (네트워크 부품)
module/network                # 네트워크 부품을 묶은 모듈
module/resource/sg            # 보안 그룹 모음
module/resource/ec2           # Bastion, NAT, Private EC2
module/resource/elb           # [1차] ALB, 대상 그룹, 리스너
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

## 비용 참고 (서울 리전, 대략)

t3.micro × 3 (Bastion, NAT, Private EC2) + [1차] ALB 1개(시간당 요금 + LCU 사용량). 실습 후에는 꼭 `terraform destroy` 하세요.
