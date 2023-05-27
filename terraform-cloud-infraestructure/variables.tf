variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}

variable "instance_name_2" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}

variable "region" {
  description = "Value of the AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "azs" {
  description = "Value of the AWS Region AZS"
  type        = list(any)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnets" {
  description = "Value of private subnets"
  type        = list(any)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "Value of public subnets"
  type        = list(any)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

