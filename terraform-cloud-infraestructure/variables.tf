variable "region" {
  description = "Value of the AWS Region"
  type        = string
  default     = ""
}

variable "azs" {
  description = "Value of the AWS Region AZS"
  type        = list(any)
  default     = []
}

variable "vpc_cidr" {
  description = "VPC cidr"
  type        = string
  default     = ""
}

variable "private_subnets_cidr" {
  description = "Value of k8s private subnets"
  type        = list(any)
  default     = []
}

variable "public_subnets_cidr" {
  description = "Value of k8s public subnets"
  type        = list(any)
  default     = []
}

variable "intra_subnets_cidr" {
  description = "Value of intra subnets"
  type        = list(any)
  default     = []
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = ""
}

variable "intra_msk_subnets" {
  description = "Value of msk intra subnets"
  type        = list(any)
  default     = ["10.0.9.0/24", "10.0.10.0/24"]
}


variable "eks_module_version" {
  description = "K8s version of the cluster"
  type       = string
  default    = "19.15.2"
}

variable "msk_kafka_version" {
  description = "kafka version of the cluster"
  type       = string
  default    = ""
}

variable "vpc_id" {
  description = "VPC Id"
  type       = string
  default    = ""
}

variable "msk_kafka_cluster_name" {
  description = "Name of the kafka cluster"
  type        = string
  default     = ""
}

variable "msk_kafka_instance_type" {
  description = "Kafka instance type"
  type        = string
  default     = ""
}

variable "eks_master_roles" {

  description = "Roles who masters the clusters"
  type        = list(object({  }))
  default     =  [{
                     userarn  = "arn:aws:iam::163305182511:root"
                     username = "Erinaldo Souza - AWS"
                     groups   = ["system:masters"]
                  },
                  {
                    userarn  = "arn:aws:iam::163305182511:group/iac_group"
                    username = "IaC Group - AWS"
                    groups   = ["system:masters"]
                  }]
}
