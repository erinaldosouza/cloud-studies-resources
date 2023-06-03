terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

data "terraform_remote_state" "public_eks" {
  backend = "remote"
  config = {
    organization = "cloud-computing-studies"
    workspaces = {
      name = "aws-studies"
    }
  }
}

provider "aws" {
  region = data.terraform_remote_state.public_eks.outputs.region
}


data "aws_eks_cluster" "public_cluster" {
  name = data.terraform_remote_state.public_eks.outputs.public_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.public_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.public_cluster.certificate_authority.0)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.public_cluster.name
    ]
  }
}
