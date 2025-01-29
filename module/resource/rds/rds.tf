resource "aws_db_subnet_group" "subnet_group" {
  subnet_ids = var.subnet_group_id
  name = "terraform_db_subnet_group"
}

resource "aws_db_instance" "rds" {
    db_name = "terraform"
    username = "admin"
    password = "qwer1234!"
    allocated_storage = 20
    max_allocated_storage = 0
    apply_immediately = null
    auto_minor_version_upgrade = true
    deletion_protection = false
    copy_tags_to_snapshot = true
    skip_final_snapshot = true
    instance_class = "db.t4g.micro"
    engine = "mysql"
    engine_version = "8.0.39"
    port = 3306
    publicly_accessible = false
    identifier = "terraform-rds"
    backup_retention_period = 1
    backup_window = "19:18-19:48"
    maintenance_window                    = "wed:18:04-wed:18:34"
    multi_az                              = false
    option_group_name                     = "default:mysql-8-0"
    parameter_group_name                  = "default.mysql8.0"
    storage_type                          = "gp2"
    storage_encrypted                     = true
    vpc_security_group_ids = [
        var.rds_sg_id
    ]
    db_subnet_group_name = aws_db_subnet_group.subnet_group.name
    tags = {
      Type = "database"
      ManagedBy = "CY-Terraform"
      Environment = var.environment
    }
}