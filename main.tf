module "network" {
  source       = "./module/network"
  project_name = var.project_name
  environment  = "development"
}

module "security_groups" {
  source                  = "./module/resource/sg"
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = module.network.vpc_cidr
  ips_for_develop_purpose = var.ips_for_develop_purpose
  app_port                = var.target_instance_port
  project_name            = var.project_name
  environment             = var.environment
}

# RDS(PostgreSQL): 데이터베이스 전용 사설 서브넷에 배치, Private EC2 의 SG 에서만 접근 가능
module "rds" {
  source              = "./module/resource/rds"
  project_name        = var.project_name
  database_subnet_ids = module.network.database_subnet_ids
  database_sg_id      = module.security_groups.database_sg_id
  environment         = var.environment
}

module "ec2_instances" {
  source                 = "./module/resource/ec2"
  vpc_id                 = module.network.vpc_id
  private_route_table_id = module.network.private_route_table_id
  private_subnet_ids     = module.network.private_subnet_ids
  public_subnet_ids      = module.network.public_subnet_ids
  bastion_sg_id          = module.security_groups.bastion_sg_id
  nat_instance_sg_id     = module.security_groups.nat_instance_sg_id
  private_server_sg_id   = module.security_groups.private_server_sg_id
  project_name           = var.project_name
  environment            = var.environment
}

# ALB: 인터넷 → (공개 서브넷) ALB → (사설 서브넷) Private EC2
module "elb" {
  source               = "./module/resource/elb"
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  alb_sg_id            = module.security_groups.alb_sg_id
  target_instance_port = var.target_instance_port
  target_instance_id   = module.ec2_instances.private_server_id
  project_name         = var.project_name
  environment          = var.environment
}
