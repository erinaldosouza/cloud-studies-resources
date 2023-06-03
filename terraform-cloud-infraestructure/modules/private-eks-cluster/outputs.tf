
output "private_cluster_endpoint" {
  description = "Endpoint for PRIVATE EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "private_cluster_security_group_id" {
  description = "Security group ids attached to the PRIVATE cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "private_cluster_name" {
  description = "Kubernetes PRIVATE Cluster Name"
  value       = module.eks.cluster_name
}
