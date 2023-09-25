
output "region" {
  description = "AWS region"
  value       = var.region
}

output "azs" {
  description = "AWS region AZs"
  value       = var.azs
}

/*
output "apigateway_api_endpoint" {
  description = "API Gateway URI"
  value       = module.apigateway.apigateway_api_endpoint
}


output "public_eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.public_eks_cluster.cluster_endpoint
}

output "public_eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.public_eks_cluster.cluster_security_group_id
}

output "public_eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.public_eks_cluster.eks_cluster_name
}*/

/*
output "private_eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.private_eks_cluster.cluster_endpoint
}

output "private_eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.private_eks_cluster.cluster_security_group_id
}

output "private_eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.private_eks_cluster.eks_cluster_name
}

output "alb_http_tcp_listener_arn" {
  description = "ALB HTTP Listener ARM"
  value       = module.public_application_load_balancer.alb_http_tcp_listener_arn
}
*/
/*
output "msk_broker_endpoints" {
  description = "Broker endpoints"
  value       = module.msk_cluster.msk_broker_endpoints
}

output "msk_cluster_name" {
  description = "Cluster name"
  value       = module.msk_cluster.msk_cluster_name
}
*/