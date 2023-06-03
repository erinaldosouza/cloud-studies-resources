
module "msk-apache-kafka-cluster" {
  source  = "cloudposse/msk-apache-kafka-cluster/aws"
  version = "2.3.0"

  broker_instance_type = "kafka.t3.small"
  kafka_version = var.msk_kafka_version
  vpc_id = var.vpc_id
  subnet_ids = var.kafka_subnet_ids
  name = var.kafka_cluster_name
  client_allow_unauthenticated = true
}