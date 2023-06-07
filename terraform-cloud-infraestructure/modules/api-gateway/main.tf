
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

  depends_on = [module.route53_zones]

}

module "apigateway-v2" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  protocol_type = "HTTP"
  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  name                        = "dev-api"
  domain_name                 = "dev-api.net"
  domain_name_certificate_arn = module.acm.acm_certificate_arn

  depends_on = [module.acm]
}