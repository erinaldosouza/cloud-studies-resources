
/*
output "region" {
  description = "AWS Region"
  value       = var.region
}

output "vpc" {
  description = "AWS VPC Id"
  value       = module.vpc.vpc_id
}

output "subnets" {
  description = "AWS VPC Publc Subnets IDs"
  value       = module.vpc.public_subnets
}

output "alb" {
  description = "AWS Application Load Balancer ARN"
  value       = module.alb.lb_arn
}

output "apigateway" {
  description = "API Gateway API ARN"
  value       = module.apigateway.apigatewayv2_api_arn
}

output "apigateway_endpoint" {
  description = "API Gateway API ARN"
  value       = module.apigateway.apigatewayv2_api_api_endpoint
}

output "apigateway_log_group" {
  description = "API Gateway Log Group ARN"
  value       = module.cloudwatch_apigw_log_group.cloudwatch_log_group_arn
}

output "apigateway_vpc_link" {
  description = "API Gateway VPC Link ARN"
  value       = module.apigateway.apigatewayv2_vpc_link_arn
}

output "ecs_cluster" {
  description = "ECS Cluster ARN"
  value       = module.ecs_cluster.arn
}

output "esc_service" {
  description = "ECS Service Id"
  value       = module.ecs_service.id
}

output "cloudfront" {
  description = "Distribution domain name"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}
*/


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