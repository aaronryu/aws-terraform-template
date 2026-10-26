
output "bastion_public_ip" {
  value = module.ec2_instances.bastion_public_ip
}

output "private_server_private_ip" {
  value = module.ec2_instances.private_server_private_ip
}

# Bastion 을 거쳐 Private EC2 로 접속하는 2단계 명령 (프로젝트 루트에서, terraform output -raw <이름> 으로 꺼내 실행)
# 1) 터미널 A: 로컬 33322 포트 → Bastion → Private EC2 의 22 포트로 터널을 연다 (-N: 원격 명령 없이 터널만 유지, 끄면 Ctrl+C)
#   - 터미널에 다음 명령어 수행 > eval "$(terraform output -raw ssh_tunnel_to_private_server)"
output "ssh_tunnel_to_private_server" {
  value = "ssh -i local-to-bastion.pem -N -L 33322:${module.ec2_instances.private_server_private_ip}:22 ec2-user@${module.ec2_instances.bastion_public_ip}"
}

# 2) 터미널 B: 열린 터널(localhost:33322)로 Private EC2 에 접속
# * 인스턴스가 재생성되면 localhost:33322 의 호스트 키가 바뀌므로 known_hosts 에 남기지 않는다
# = StrictHostKeyChecking=no + UserKnownHostsFile=/dev/null 옵션 덕분에 localhost:33322 의 호스트 키가 바뀌어도 known_hosts 에 남기지 않아 오류 발생 방지
#   - 터미널에 다음 명령어 수행 > eval "$(terraform output -raw ssh_to_private_server)"
output "ssh_to_private_server" {
  value = "ssh -i local-to-private.pem -p 33322 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@localhost"
}

# ALB 도입되고나서는 단일 도메인명으로 웹브라우저나 클라이언트로 접속하게 된다 - 재배포되어도 변하지않는다
output "alb_dns_name" {
  value = module.elb.alb_dns_name
}

# 대상 그룹 헬스체크 상태 확인용 > aws elbv2 describe-target-health --target-group-arn $(terraform output -raw ec2_target_group_arn)
output "ec2_target_group_arn" {
  value = module.elb.ec2_target_group_arn
}
