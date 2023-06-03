variable "msk_kafka_version" {
  description = "Kafka version"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC Id"
  type       = string
  default    = ""
}

variable "kafka_subnet_ids" {
  description = "Value of kafka subnet ids"
  type        = list(any)
  default     = []
}

variable "kafka_cluster_name" {
  description = "Name of the kafka cluster"
  type        = string
  default     = ""
}