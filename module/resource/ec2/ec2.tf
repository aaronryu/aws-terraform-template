resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "local_file" "private_key_server" {
    content = tls_private_key.server.private_key_pem
    filename = "${path.module}/private-key-for-server.pem"
}

resource "local_file" "private_key_bastion" {
    content = tls_private_key.bastion.private_key_pem
    filename = "${path.module}/private-key-for-bastion.pem"
}

resource "aws_key_pair" "server" {
    key_name = "server-for-ssh"
    public_key = tls_private_key.server.public_key_openssh  
}

resource "aws_key_pair" "bastion" {
    key_name = "bastion-for-ssh"
    public_key = tls_private_key.bastion.public_key_openssh
}

output "private_key_bastion" {
    value = tls_private_key.bastion.private_key_pem
    sensitive = true
}

output "private_key_server" {
    value = tls_private_key.server.private_key_pem
    sensitive = true
}


resource "aws_instance" "server" {
    ami = "ami-049788618f07e189d"
    instance_type = "t2.micro"
    subnet_id = var.subnet_id
    vpc_security_group_ids = [
        var.server_sg_id
    ]
    key_name = aws_key_pair.server.key_name
    associate_public_ip_address = true
    user_data = <<EOF
#!/bin/bash -xe
sudo yum upgrade -y && yum update -y
sudo yum install docker -y
sudo service docker start
EOF

    tags = {
      Name = "server-ec2-instance"
      ManagedBy = "CY-Terraform"
      Environment = var.environment
    }
}

resource "aws_instance" "bastion" {
    ami = "ami-049788618f07e189d"
    instance_type = "t2.micro"
    subnet_id = var.subnet_id
    vpc_security_group_ids = [
        var.bastion_sg_id
    ]
    key_name = aws_key_pair.bastion.key_name
    associate_public_ip_address = true

    tags = {
      Name = "bastion-ec2-instance"
      ManagedBy = "CY-Terraform"
      Environment = var.environment
    }
}