provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "devops-cloud-studies"
      Project     = "DevOps Cloud Environment"
    }
  }
}

/* Cria uma VPC com subnets publicas */
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets_cidr

  enable_nat_gateway      = false
  single_nat_gateway      = true

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
      backend_protocol = "http"
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
        protocol            = "http"
        matcher             = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "http"
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

  default_stage_access_log_format           = "{ 'requestId':'$context.requestId', 'ip': '$context.identity.sourceIp', 'requestTime':'$context.requestTime', 'httpMethod':'$context.httpMethod','routeKey':'$context.routeKey', 'status':'$context.status','protocol':'$context.protocol', 'errorResponeType': '$context.error.responseType', 'responseLength':'$context.responseLength' , 'authorizerError':'$context.authorizer.error', 'errorMessage':'$context.error.message', 'msgString':'$context.error.messageString'}"
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

module "cloudwatch_log-group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "4.3.0"

  name              = "apigw-log-group"
  retention_in_days = 1

}