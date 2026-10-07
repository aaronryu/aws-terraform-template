
module "vpc" {
  source      = "../common/vpc"
  environment = var.environment
}

module "subnets" {
  source      = "../common/subnets"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "igw" {
  source      = "../common/igw"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "route_table" {
  source      = "../common/route-tables"
  vpc_id      = module.vpc.vpc_id
  igw_id      = module.igw.igw_id
  environment = var.environment
}

module "route_table_association" {
  source                 = "../common/route-tables-association"
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.subnets.public_subnet_ids
  public_route_table_id  = module.route_table.public_route_table_id
  private_subnet_ids     = module.subnets.private_subnet_ids
  private_route_table_id = module.route_table.private_route_table_id
}
