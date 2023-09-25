variable "cluster_name" {
  description = "Value of VPC Id"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "Value of VPC Id"
  type        = string
  default     = ""
}

variable "k8s_subnet_ids" {
  description = "Value of k8s private subnets"
  type        = list(any)
  default     = []
}

variable "eks_k8s_version" {
  description = "K8s version of the cluster"
  type       = string
  default    = "1.27"
}

variable "region" {
  description = "Value of the AWS Region"
  type        = string
  default     = ""
}

