# Get the default VPC
data "aws_vpc" "default_vpc" {
  default=true
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id  = data.aws_vpc.default_vpc.id
  project = var.project
}

module "iam" {
  source = "./modules/iam"

  project = var.project
}

module "ec2" {
  source = "./modules/ec2"

  instance_type        = var.instance_type
  security_group_ids   = [module.security_groups.web_sg_id]
  iam_instance_profile = module.iam.instance_profile_name
  project              = var.project
}
