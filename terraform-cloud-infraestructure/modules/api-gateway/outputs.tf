
output "apigateway_api_endpoint" {
  description = "API Gateway URI"
  value       = module.apigateway-v2.apigatewayv2_api_api_endpoint
}

output "acm_certificate_arn" {
  description = "Certificate ARN"
  value       = module.acm.acm_certificate_arn
}

