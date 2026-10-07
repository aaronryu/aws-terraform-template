
# TLS 키 생성
resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_private_key" "private_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 로컬 로컬 파일로 pem 키 저장
resource "local_file" "private_key_bastion" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.root}/local-to-bastion.pem"
  file_permission = "0600"
}

resource "local_file" "private_key_private_server" {
  content         = tls_private_key.private_server.private_key_pem
  filename        = "${path.root}/local-to-private.pem"
  file_permission = "0600"
}

# terraform output 통해 뽑아낼수도 있는데 위의 pem 키 파일 로컬 저장 방식을 더 추천
# terraform output -raw private_key_bastion > bastion-key.pem + chmod 600 bastion-key.pem
# output "private_key_bastion" {
#     value = tls_private_key.bastion.private_key_pem
#     sensitive = true
# }

# output "private_key_server" {
#     value = tls_private_key.server.private_key_pem
#     sensitive = true
# }

# AWS Key Pair 등록
resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "aws_key_pair" "private_server" {
  key_name   = "private-server-key"
  public_key = tls_private_key.private_server.public_key_openssh
}
