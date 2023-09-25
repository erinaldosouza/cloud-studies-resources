
output "apigateway_api_endpoint" {
  description = "API Gateway URI"
  value       = module.apigateway-v2.apigatewayv2_api_api_endpoint
}

output "api_gateway_security_group_ids" {
  description = "API Gateway security group ids"
  value       = [module.api_gateway_security_group.security_group_id]
}

