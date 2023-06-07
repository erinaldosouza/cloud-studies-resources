
output "public_cluster_endpoint" {
  description = "Endpoint for PUBLIC EKS control plane"
  value       = module.public_eks.public_cluster_endpoint
}

output "public_cluster_security_group_id" {
  description = "Security group ids attached to the PUBLIC cluster control plane"
  value       = module.public_eks.public_cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "public_cluster_name" {
  description = "Kubernetes PUBLIC Cluster Name"
  value       = module.public_eks.public_cluster_name
}

output "apigateway_api_endpoint" {
  description = "API Gateway URI"
  value       = module.apigateway.apigateway_api_endpoint
}