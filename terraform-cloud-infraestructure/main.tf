provider "aws" {
  region = var.region

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true

  # Default tags to all aws services / resources
  default_tags {
    tags = {
      Environment = "devops-cloud-studies"
      Project     = "DevOps Cloud Environment"
    }
  }
}

locals {
  # This id is copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
  default_response_headers_policy_id =  "67f7725c-6f97-4210-82d7-5512b31e9d03"

  # This is id for SecurityHeadersPolicy copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
  default_cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

/* Cria uma VPC com subnets publicas */
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets_cidr

  enable_nat_gateway = false
  single_nat_gateway = true

}

/* Cria um ALB na VPC para fazer o balanceamento entre as suas subnets */
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  internal        = true
  name            = "alb-cloud-studies"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.trafic_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "tg-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 6
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "forward"
    }
  ]

}

/* Cria uma IAM Role com Admin Permissions (default) */
module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.30.0"

  role_name             = "ecs-cluster-role"
  role_description      = "IAM Role para cloud studies"
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

}

/* Cria um Cluster ECS */
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.2"

  cluster_name            = "ecs-cluster-cloud-studies"
  task_exec_iam_role_name = module.iam_assumable_role.iam_role_name
  task_exec_iam_role_path = module.iam_assumable_role.iam_role_path

}

/* Cria um Service ECS no cluster, as subnets, a role e o load balancer criado anteriormente */
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.2"

  name             = "ecs-service-cloud-studies-2"
  family           = "family-cloud-studies"
  cluster_arn      = module.ecs_cluster.arn
  subnet_ids       = module.vpc.public_subnets
  assign_public_ip = true

  iam_role_arn            = module.iam_assumable_role.iam_role_arn
  tasks_iam_role_arn      = module.iam_assumable_role.iam_role_arn
  task_exec_iam_role_arn  = module.iam_assumable_role.iam_role_arn

  security_group_ids = [module.trafic_security_group.security_group_id]

  container_definitions = {
    ecs-service-cloud-studies = {
      essential                = true
      image                    = "public.ecr.aws/nginx/nginx:latest"
      readonly_root_filesystem = false

      port_mappings = [
        {
          name          = "ecs-service-nginx"
          containerPort = 80
          protocol      = "HTTP"
        }
      ]

      health_check = {
        retries = 5
        command = ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]
      }
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_group_arns[0]
      container_name   = "ecs-service-cloud-studies"
      container_port   = 80
    }
  }
}

/* Cria um security group para ser usado no API Gateway que será criado */
module "trafic_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "default-trafic-sg-cloud-studies"
  description = "API Gateway group for example usage"
  vpc_id      = module.vpc.vpc_id

  egress_rules        = ["all-all"]
  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]


}

/* Cria um API Gateway para acessar o cluster ECS via VPC Link */
module "apigateway-v2" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name                   = "apigw-cloud-studies"
  description            = "API Gateway for cloud studies"
  create_api_domain_name = false

  default_stage_access_log_format          = "{ 'requestId':'$context.requestId', 'ip': '$context.identity.sourceIp', 'requestTime':'$context.requestTime', 'httpMethod':'$context.httpMethod','routeKey':'$context.routeKey', 'status':'$context.status','protocol':'$context.protocol', 'errorResponeType': '$context.error.responseType', 'responseLength':'$context.responseLength' , 'authorizerError':'$context.authorizer.error', 'errorMessage':'$context.error.message', 'msgString':'$context.error.messageString'}"
  default_stage_access_log_destination_arn = module.cloudwatch_log-group.cloudwatch_log_group_arn

  integrations = {
    "GET /" = {
      connection_type    = "VPC_LINK"
      vpc_link           = "my-vpc"
      integration_uri    = module.alb.http_tcp_listener_arns[0]
      integration_type   = "HTTP_PROXY"
      integration_method = "ANY"
    }

  }

  vpc_links = {
    my-vpc = {
      name               = "vpc-link-cloud-studies"
      security_group_ids = [module.trafic_security_group.security_group_id]
      subnet_ids         = module.vpc.public_subnets
    }
  }

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

}

/* Cria o log group para logs do API Gateway */
module "cloudwatch_log-group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "4.3.0"

  name              = "apigw-log-group"
  retention_in_days = 1

}

/* Cria uma key para criptografias */
/*
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.0.1"

  description = "Chave para testes com KMS"
  aliases = ["alias/kmstestkey"]
  enable_key_rotation = true

}
*/
/* Cria uma secret com um valor fixo (valor do atributo "secret_string") que deve ser critografado usando a Key criada anteriormente */
/*
module "secrets-manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.1"

  name = "cloud-studies-secret"
  description = "Segredo para testes com Secret Manager"
  kms_key_id = module.kms.key_id
  secret_string = jsonencode({ data : "secret value here" })

}
*/
/* Cria o S# para armezenar a aplicação front an statica (ex: um angular app, arquivos .html etc) */
module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

 # create_bucket = false
#  control_object_ownership = true
#  object_ownership         = "BucketOwnerPreferred"
  bucket                   = "s3-bkt-cloud-studies"
  force_destroy            = true
  # attach_public_policy   = false
 # block_public_acls        = false
  #block_public_policy      = false
  #ignore_public_acls       = false
 # attach_policy            = true
  #acl                      = "public-read"
 #restrict_public_buckets  = false

 /* policy = tostring(jsonencode(
    {
      Version: "2012-10-17"
      Statement : [
        {
          Sid : "AllowEveryoneReadOnlyAccess"
          Principal : "*"
          Effect : "Allow"
          Action : [
            "s3:*"
          ]
          Resource: "arn:aws:s3:::s3-bkt-cloud-studies"
        }
      ]
    }
  ))*/
  # allowed_kms_key_arn = module.kms.key_arn

  website = {

    index_document = "index.html"
    error_document = "error.html"
    cors_rule = [
      {
        allowed_methods = ["GET", "PUT", "POST", "DELETE"]
        allowed_origins = ["*"]
        allowed_headers = ["*"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3000
      }
    ]
   /* routing_rules = [
      {
        condition = {
          key_prefix_equals = "docs/"
        },
        redirect = {
          replace_key_prefix_with = "documents/"
        }
      },
      {
        condition = {
          http_error_code_returned_equals = 404
          key_prefix_equals               = "archive/"
        },
        redirect = {
          host_name          = "archive.myhost.com"
          http_redirect_code = 301
          protocol           = "https"
          replace_key_with   = "not_found.html"
        }
      }
    ]*/
  }

}

module "dir" {
  source  = "hashicorp/dir/template"
  version = "1.0.2"

  base_dir = "${path.module}/my-precoocked-startup-app"
  template_vars = {
    # Pass in any values that you wish to use in your templates.
    vpc_id = module.vpc.vpc_id
  }
}

/*
resource "null_resource" "remove_and_upload_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/s3Contents s3://${module.s3-bucket.s3_bucket_id}"
  }
}
*/

module "s3-bucket_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "3.15.1"

  depends_on = [module.s3-bucket]

  # create = false
  for_each      = module.dir.files
  bucket        = module.s3-bucket.s3_bucket_id
  file_source   = each.value.source_path
  content_type  = each.value.content_type
  key           = each.key
  acl           = null
  force_destroy = true



}

/* Cria uma cloud front para armazenamento de conteúdo estatico do S3 e tambem do API Gateway*/
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  price_class = "PriceClass_All"

  create_origin_access_control = true
  origin_access_control = {
    front-app-s3 = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    web-api = {
      domain_name          = replace(module.apigateway-v2.apigatewayv2_api_api_endpoint, "https://", "")
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    front-app-s3 = {
      domain_name      = module.s3-bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control = "front-app-s3"
    }

  }

  default_cache_behavior = {
    path_pattern           = "/*"
    target_origin_id       = "web-api"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true

    min_ttl     = 3600
    default_ttl = 3600
    max_ttl     = 3600

    cache_policy_id            = local.default_cache_policy_id
    response_headers_policy_id = local.default_response_headers_policy_id
    use_forwarded_values       = false
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "web-api"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      min_ttl     = 3600
      default_ttl = 3600
      max_ttl     = 3600

      cache_policy_id            = local.default_cache_policy_id
      response_headers_policy_id = local.default_response_headers_policy_id
      use_forwarded_values       = false
    },

    {
      path_pattern           = "/*.html"
      target_origin_id       = "front-app-s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      min_ttl     = 3600
      default_ttl = 3600
      max_ttl     = 3600

      cache_policy_id            = local.default_cache_policy_id
      response_headers_policy_id = local.default_response_headers_policy_id
      use_forwarded_values       = false
    },
    {
      path_pattern           = "/*.js"
      target_origin_id       = "front-app-s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      min_ttl     = 3600
      default_ttl = 3600
      max_ttl     = 3600

      cache_policy_id            = local.default_cache_policy_id
      response_headers_policy_id = local.default_response_headers_policy_id
      use_forwarded_values       = false
    },
    {
      path_pattern           = "/*.css"
      target_origin_id       = "front-app-s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      min_ttl     = 3600
      default_ttl = 3600
      max_ttl     = 3600

      cache_policy_id            = local.default_cache_policy_id
      response_headers_policy_id = local.default_response_headers_policy_id
      use_forwarded_values       = false
    },
    {
      path_pattern           = "/*.ico"
      target_origin_id       = "front-app-s3"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      min_ttl     = 3600
      default_ttl = 3600
      max_ttl     = 3600

      cache_policy_id            = local.default_cache_policy_id
      response_headers_policy_id = local.default_response_headers_policy_id
      use_forwarded_values       = false
    }

  ]

}


/*

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.1"

  identifier = "rds-cloud-studies"
  db_name = "mydql-db"
  engine = "mysql"
  family = "MySQL-8"
  engine_version = "8.0.33"
  major_engine_version = "8"
  instance_class = "db.t4g.micro"

  subnet_ids = module.main_vpc.public_subnet_ids

  tags = {
    Environment = "cloud-studies"
  }
}
*/