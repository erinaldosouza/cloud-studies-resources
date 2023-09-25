variable "vpc_id" {
  description = "VPC Id"
  type       = string
  default    = ""
}

variable "msk_kafka_subnet_ids" {
  description = "Value of kafka subnet ids"
  type        = list(any)
  default     = []
}

variable "msk_kafka_version" {
  description = "Kafka version"
  type        = string
  default     = ""
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