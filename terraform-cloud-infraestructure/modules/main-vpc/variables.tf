variable "azs" {
  description = "Value of the AWS Region AZS"
  type        = list(any)
  default     = []
}

variable "private_subnets_cidr" {
  description = "Value of private subnets"
  type        = list(any)
  default     = []
}

variable "public_subnets_cidr" {
  description = "Value of public subnets"
  type        = list(any)
  default     = []
}

variable "intra_subnets_cidr" {
  description = "Value of intra subnets"
  type        = list(any)
  default     = []
}


variable "vpc_cidr" {
  description = "VPC cidr"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = ""
}