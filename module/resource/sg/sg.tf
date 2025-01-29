resource "aws_security_group" "server" {
    name = "terraform-dev-server-sg"
    vpc_id = var.vpc_id
    description = "inbound : ssh + tcp / outbound: all"
    ingress = [
        {
            cidr_blocks = [
                "0.0.0.0/0",
            ]
            description = "ssh from all ips"
            from_port = 22
            to_port = 22
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
        },
        {
            cidr_blocks = [
                "0.0.0.0/0",
            ]
            description = "tcp from all ips"
            from_port = 8080
            to_port = 8080
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
        }
    ]
    
    egress = [
        {
            cidr_blocks = [
                "0.0.0.0/0",
            ]
            description = ""
            from_port = 0
            to_port = 0
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = -1
            security_groups  = []
            self             = false
        }
    ]
    
    tags = {
        Name = "terraform-dev-server-sg"
        ManagedBy = "CY-Terraform"
        Environment = var.environment
    }
}


resource "aws_security_group" "bastion" {
    name = "bastion-dev-sg"
    vpc_id = var.vpc_id
    description = "inbound: SSH + all ips / outbound: all ips + all protocols"
    ingress = [
        {
            cidr_blocks = [
                "0.0.0.0/0",
            ]
            description = "ssh from all ips"
            from_port = 22
            to_port = 22
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
        },
    ]
    
    egress = [
        {
            cidr_blocks = [
                "0.0.0.0/0",
            ]
            description = ""
            from_port = 0
            to_port = 0
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = -1
            security_groups  = []
            self             = false
        }
    ]
    
    tags = {
        Name = "terraform-dev-bastion-sg"
        ManagedBy = "CY-Terraform"
        Environment = var.environment
    }
}



resource "aws_security_group" "rds" {
    name = "rds-sg"
    vpc_id = var.vpc_id
    description = "inbound : server, bastion / outbound : all protocols"
    tags = {
        Name = "rds-security-group"
        ManagedBy = "CY-Terraform"
        Environment = var.environment
    }
    ingress = [
        {
            cidr_blocks = []
            description = "MySQL inbound from server and bastion"
            from_port = 3306
            to_port = 3306
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            protocol = "tcp"
            security_groups = [
                "${aws_security_group.server.id}",
                "${aws_security_group.bastion.id}",
            ]
            self = false
        }
    ]
    egress = [
        {
            cidr_blocks = ["0.0.0.0/0"]
            description = "allow all outbound"
            from_port = 0
            to_port = 0
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            protocol = -1
            security_groups = []
            self = false
        }
    ]
}
