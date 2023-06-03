
locals {
  cluster_name = "public-cloud-computing"
}

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.2"

  vpc_id          = var.vpc_id
  subnet_ids      =  var.public_k8s_subnet_ids
  cluster_name    = "${local.cluster_name}"
  cluster_version = var.eks_k8s_version

  cluster_endpoint_public_access = true

  //TODO Verificar configs
  //create_aws_auth_configmap = true
  //manage_aws_auth_configmap = true
  //aws_auth_roles = var.eks_master_roles

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name           = "private-node-group-1"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }

}
