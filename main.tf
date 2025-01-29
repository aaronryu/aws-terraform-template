# credential은 IAM CY 계정꺼(terraform이라고 써있는거)
provider "aws" {
  region = "ap-northeast-2"

}

module "network" {
  source      = "./module/network"
  environment = "development"
}

module "security_groups" {
  source      = "./module/resource/sg"
  vpc_id      = module.network.vpc_id
  environment = "development"
}

module "ec2_instances" {
  source        = "./module/resource/ec2"
  vpc_id        = module.network.vpc_id
  subnet_id     = module.network.pub_sub_0_id
  bastion_sg_id = module.security_groups.bastion_sg_id
  server_sg_id  = module.security_groups.server_sg_id
  environment   = "development"
}

module "rds" {
  source          = "./module/resource/rds"
  rds_sg_id       = module.security_groups.rds_sg_id
  subnet_group_id = [module.network.pri_sub_0_id, module.network.pri_sub_1_id]
  environment     = "development"
}

module "ecr" {
  source        = "./module/resource/ecr"
  registry_name = "ecr-test"
}

module "iams" {
  source = "./module/resource/iam"
}

module "s3" {
  source     = "./module/resource/s3"
  iam_for_s3 = module.iams.s3_arn
}