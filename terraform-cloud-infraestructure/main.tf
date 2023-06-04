
provider "aws" {
  region = var.region
}

locals {
  cluster_name = "cloud-computing" /*${random_string.suffix.result}"*/
}

module "main_vpc" {
  source  = "./modules/main-vpc"

  vpc_name             = var.vpc_name
  azs                  = var.azs
  vpc_cidr             = var.vpc_cidr
  private_subnets_cidr = var.private_subnets_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  intra_subnets_cidr   = var.intra_subnets_cidr

}

module "private_eks" {
  source  = "./modules/private-eks-cluster"

  vpc_id = module.main_vpc.vpc_id
  private_k8s_subnet_ids = module.main_vpc.private_subnet_ids

}

module "public_eks" {
  source  = "./modules/public-eks-cluster"

  vpc_id = module.main_vpc.vpc_id
  public_k8s_subnet_ids = module.main_vpc.public_subnet_ids

}

module "msk_cluster" {
  source = "./modules/intra-msk-cluster"

  vpc_id                  = module.main_vpc.vpc_id
  msk_kafka_subnet_ids    = module.main_vpc.intra_subnet_ids
  msk_kafka_cluster_name  = var.msk_kafka_cluster_name
  msk_kafka_version       = var.msk_kafka_version
  msk_kafka_instance_type = var.msk_kafka_instance_type

}
