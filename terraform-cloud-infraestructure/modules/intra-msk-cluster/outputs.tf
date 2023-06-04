output "broker_endpoints" {
  description = "Broker endpoints"
  value       = module.msk-apache-kafka-cluster.broker_endpoints
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.msk-apache-kafka-cluster.cluster_name
}
