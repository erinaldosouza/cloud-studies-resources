variable "nlb_http_tcp_listener_arn" {
  description = "NLB URI"
  type        = list(any)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets"
  type        = list(any)
  default     = []
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = ""
}
