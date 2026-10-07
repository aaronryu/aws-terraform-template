module "network" {
  source      = "./module/network"
  environment = "development"
}

module "security_groups" {
  source      = "./module/resource/sg"
  vpc_id      = module.network.vpc_id
  vpc_cidr    = module.network.vpc_cidr
  environment = "development"
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
  environment            = "development"
}
