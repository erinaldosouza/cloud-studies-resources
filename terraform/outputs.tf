/*output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}*/

output "public_cluster_endpoint" {
  description = "Endpoint for PUBLIC EKS control plane"
  value       = module.public_eks.cluster_endpoint
}

output "private_cluster_endpoint" {
  description = "Endpoint for PRIVATE EKS control plane"
  value       = module.private_eks.cluster_endpoint
}

output "public_cluster_security_group_id" {
  description = "Security group ids attached to the PUBLIC cluster control plane"
  value       = module.public_eks.cluster_security_group_id
}

output "private_cluster_security_group_id" {
  description = "Security group ids attached to the PRIVATE cluster control plane"
  value       = module.private_eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "public_cluster_name" {
  description = "Kubernetes PUBLIC Cluster Name"
  value       = module.public_eks.cluster_name
}

output "private_cluster_name" {
  description = "Kubernetes PRIVATE Cluster Name"
  value       = module.private_eks.cluster_name
}
