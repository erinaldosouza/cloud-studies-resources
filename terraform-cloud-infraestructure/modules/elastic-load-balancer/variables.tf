variable "vpc_id" {
  description = "VPC Id"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet Ids"
  type        = list(any)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups Ids"
  type        = list(any)
  default     = null
}