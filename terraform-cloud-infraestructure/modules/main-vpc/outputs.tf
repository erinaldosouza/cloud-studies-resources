
output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
description = "private subnet ids"
value       = module.vpc.private_subnets
}

output "vpc_id" {
  description = "VPC Id"
  value       = module.vpc.vpc_id
}

