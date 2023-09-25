
locals {
  cluster_name = "cloud-computing" /*${random_string.suffix.result}"*/
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.azs
  create_igw      = true
  public_subnets  = var.public_subnets_cidr
  private_subnets = var.private_subnets_cidr
  intra_subnets   = var.intra_subnets_cidr

  enable_nat_gateway      = false
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  public_inbound_acl_rules = [
    {
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "http"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  public_outbound_acl_rules = [
    {
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "http"
      cidr_block  = "0.0.0.0/0"
    }
  ]

  /*
  public_subnet_tags = {
    "kubernetes.io/cluster/public-${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/private-${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  */

}