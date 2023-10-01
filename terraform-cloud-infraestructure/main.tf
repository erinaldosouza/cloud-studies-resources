provider "aws" {
  region = var.region

  # Default tags to all aws services / resources
  default_tags {
    tags = {
      Project     = "Production-ready AWS Cloud Environment"
      Environment = "DevOps Cloud Studies"
      Description = "A basic but good enough AWS cloud environment built to accelerate low budget backyards startups when it comes to Delivering on Production Environment"
      PoweredBy   = "Erinaldo Souza. Developer since 2023, Web System Architecture and Design Especialis, Oracle and AWS Certified Professional, DevOps enthusiast. A long term learner"
    }
  }
}

locals {
  # This id is copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
  default_response_headers_policy_id =  "67f7725c-6f97-4210-82d7-5512b31e9d03"

  # This is id for SecurityHeadersPolicy copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
  default_cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"

  # Cache time in seconds
  default_cache_ttl_seconds          = 30
}

/* Cria uma VPC com subnets publicas */
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name             = var.vpc_name
  cidr             = var.vpc_cidr
  azs              = var.azs
  public_subnets   = var.public_subnets_cidr
  # database_subnets = var.database_subnets_cidr
  # create_database_subnet_route_table = true

  enable_nat_gateway = false
  single_nat_gateway = true

}

/* Cria um security group para ser usado no API Gateway que será criado */
module "in_out_traffic_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "default-trafic-sg-cloud-studies"
  description = "API Gateway group for example usage"
  vpc_id      = module.vpc.vpc_id

  egress_rules        = ["all-all"]
  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

}

/* Cria um ALB na VPC para fazer o balanceamento entre as suas subnets */
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  internal        = true
  name            = "alb-cloud-studies"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.in_out_traffic_security_group.security_group_id]

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
  assign_public_ip = true // Necessary to pull images from public container registries

  iam_role_arn            = module.iam_assumable_role.iam_role_arn
  tasks_iam_role_arn      = module.iam_assumable_role.iam_role_arn
  task_exec_iam_role_arn  = module.iam_assumable_role.iam_role_arn
  security_group_ids      = [module.in_out_traffic_security_group.security_group_id]

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
      vpc_link           = "apigw-vpclink"
      integration_uri    = module.alb.http_tcp_listener_arns[0]
      integration_type   = "HTTP_PROXY"
      integration_method = "ANY"
    }

  }

  vpc_links = {
    apigw-vpclink = {
      name               = "apigw-vpc-link-cloud-studies"
      security_group_ids = [module.in_out_traffic_security_group.security_group_id]
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

/* Cria o S# para armezenar a aplicação front an statica (ex: um angular app, arquivos .html etc) */
module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket          = "s3-bkt-cloud-studies"
  force_destroy   = true

}

/* Mapeia referencias aos arquivos da aplicacao angular para a realizacao do deploy no S3 Bucket */
module "dir" {
  source  = "hashicorp/dir/template"
  version = "1.0.2"

  base_dir      = "${path.module}/my-precoocked-startup-app"
  template_vars = {
    # Pass in any values that you wish to use in your templates.
    vpc_id = module.vpc.vpc_id
  }
}

/* Faz o deploy da aplicacao angular no bucket S3 criado */
module "s3-bucket_object" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "3.15.1"

  depends_on = [module.s3-bucket]

  for_each      = module.dir.files

  bucket        = module.s3-bucket.s3_bucket_id
  file_source   = each.value.source_path
  content_type  = each.value.content_type
  key           = "web-app/${each.key}"
  acl           = "private"
  force_destroy = true

}

/* Cria uma cloud front para armazenamento de conteúdo estatico do S3 e tambem do API Gateway */
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  depends_on = [module.s3-bucket_object]

  price_class                  = "PriceClass_All"
  default_root_object          = "index.html"
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
    front-app-s3 = {
      domain_name           = module.s3-bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control = "front-app-s3"
    }
  }

  default_cache_behavior =     {
    path_pattern           = "/*"
    target_origin_id       = "front-app-s3"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true

    min_ttl     = local.default_cache_ttl_seconds
    default_ttl = local.default_cache_ttl_seconds
    max_ttl     = local.default_cache_ttl_seconds

    cache_policy_id            = local.default_cache_policy_id
    response_headers_policy_id = local.default_response_headers_policy_id
    use_forwarded_values       = false

  }

  // ordered_cache_behavior = []
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
  subnet_ids = module.vpc.database_subnets

}
*/


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