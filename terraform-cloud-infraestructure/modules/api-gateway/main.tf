/*
module "route53_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.10.2"

  zones = {
    "dev-api.net" = {
      comment = "terraform-aws-modules-examples.com (dev)"
      tags    = {
        env = "dev-api"
      }
    }
  }

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.3.2"

  domain_name = "dev-api.net"
  zone_id     = module.route53_zones.route53_zone_zone_id["dev-api.net"]
  validation_allow_overwrite_records = true

  wait_for_validation  = true
  validation_timeout   = "10000h"
  validate_certificate = true
  validation_method    = "DNS"

  create_certificate   = false

  depends_on = [module.route53_zones]

}
*/


module "apigateway-v2" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

 /*
  domain_name            = "domain.com.br"
  domain_name_certificate_arn = module.acm.acm_certificate_arn
  depends_on = [module.acm]
  */

  name = "Dev APIs"
  create_api_domain_name = false
  description            = "Dev API Gateway used to test"
  api_version            = "0.beta"
  protocol_type          = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

 // target = "http://www.google.com"

  vpc_links = {
    my-vpc = {
      name               = "eks-link"
      security_group_ids = [module.api_gateway_security_group.security_group_id]
      subnet_ids         = var.subnet_ids

    }
  }

  integrations = {

    "GET /" = {
      connection_type    = "VPC_LINK"
      integration_type   = "HTTP_PROXY"
      vpc_link           = "my-vpc"
      integration_uri    = var.nlb_http_tcp_listener_arn[0]
      integration_method = "ANY"
    }
/*
    "GET ${var.eks_cluster_endpoint}" = {
      connection_type    = "VPC_LINK"
      vpc_link           = "my-vpc"
      integration_uri    = var.alb_http_tcp_listener_arn
      integration_type   = "HTTP_PROXY"
      integration_method = "ANY"
    }
*/
  }

  default_stage_access_log_format = "$context.extendedRequestId"
  default_stage_access_log_destination_arn = module.cloudwatch_log-group.cloudwatch_log_group_arn

}

module "api_gateway_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "api-gateway"
  vpc_id      = var.vpc_id
  description = "API Gateway group for example usage"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  egress_rules = ["all-all"]
}

module "cloudwatch_log-group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "4.3.0"

  name = "api-gateway-log-group"
  retention_in_days = 1

}