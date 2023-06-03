
output "public_cluster_endpoint" {
  description = "Endpoint for PUBLIC EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "public_cluster_security_group_id" {
  description = "Security group ids attached to the PUBLIC cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "public_cluster_name" {
  description = "Kubernetes PUBLIC Cluster Name"
  value       = module.eks.cluster_name
}
