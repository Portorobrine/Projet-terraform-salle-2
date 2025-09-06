terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a recent version
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Provider AWS
provider "aws" {
  region = var.region
}

module "phase1" {
  source = "./phase1"
}
module "phase2" {
  source = "./phase2"
  vpc_id = module.phase1.vpc_id
}
module "phase4" {
  source = "./phase4"
  db_private_subnet_ids = module.phase1.db_private_subnet_ids
  sg_db_id = module.phase2.sg_db_id
}
module "phase3" {
  source = "./phase3"
  vpc_id = module.phase1.vpc_id
  app_private_subnet_ids = module.phase1.app_private_subnet_ids
  public_subnet_id = module.phase1.web_public_subnet_ids[0]
  bastion_ssh_key = module.phase2.bastion_key_name
  sg_bastion_id = module.phase2.sg_bastion_id
  sg_app_id = module.phase2.sg_app_id
  rds_endpoint = module.phase4.rds_endpoint
  db_password = module.phase4.db_password
}
module "phase5" {
  source              = "./phase5"
  vpc_id              = module.phase1.vpc_id
  web_public_subnet_ids = module.phase1.web_public_subnet_ids
  app_instance_ids    = module.phase3.app_instance_ids
  sg_web_id           = module.phase2.sg_web_id
}