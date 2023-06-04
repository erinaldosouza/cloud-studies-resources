
module "msk-apache-kafka-cluster" {
  source  = "cloudposse/msk-apache-kafka-cluster/aws"
  version = "2.3.0"

  vpc_id               = var.vpc_id
  subnet_ids           = var.msk_kafka_subnet_ids
  kafka_version        = var.msk_kafka_version
  name                 = var.msk_kafka_cluster_name
  broker_instance_type = var.msk_kafka_instance_type

  client_allow_unauthenticated = true
}