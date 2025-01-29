# # credential은 IAM CY 계정꺼(terraform이라고 써있는거)
provider "aws" {
  region = "ap-northeast-2"
}

module "aws_vpc" {
  source = "../common/vpc"
  environment = var.environment
}

module "subnets" {
  source = "../common/subnets"
  vpc_id = module.aws_vpc.vpc_id
  environment = var.environment
}

module "igw" {
  source = "../common/igw"
  vpc_id = module.aws_vpc.vpc_id
  environment = var.environment
}

module "route_table" {
  source = "../common/route-tables"
  vpc_id = module.aws_vpc.vpc_id
  igw_id = module.igw.igw_id
  environment = var.environment
}

module "route_table_association" {
  source       = "../common/rt-association"
  environment = var.environment
  vpc_id       = module.aws_vpc.vpc_id
  pub_rt_id    = module.route_table.pub_rt_id
  pri_rt_id    = module.route_table.pri_rt_id
  pub_sub_0_id = module.subnets.pub_sub_0_id
  pub_sub_1_id = module.subnets.pub_sub_1_id
  pri_sub_0_id = module.subnets.pri_sub_0_id
  pri_sub_1_id = module.subnets.pri_sub_1_id
}
