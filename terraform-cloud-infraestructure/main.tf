
provider "aws" {
  region = var.region
}

/* Cria a VPC principal */
module "main_vpc" {
  source  = "./modules/main-vpc"

  vpc_name             = var.vpc_name
  azs                  = var.azs
  vpc_cidr             = var.vpc_cidr
  // private_subnets_cidr = var.private_subnets_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  // intra_subnets_cidr   = var.intra_subnets_cidr

}

/* Cria uma key para criptografias */
/*
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.0.1"

  description = "Chave para testes com KMS"
  aliases = ["alias/kmstestkey"]
  enable_key_rotation = true

  tags = {
    Environment = "cloud-studies"
  }
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
  secret_string = "secret_value_here"

  tags = {
    Environment = "cloud-studies"
  }
}
*/
/* Cria um ALB na VPC principal para fazer o balanceamento entre es suas subnets */
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  internal = true
  name = "alb-cloud-studies"
  load_balancer_type = "application"
  vpc_id = module.main_vpc.vpc_id
  subnets = module.main_vpc.public_subnet_ids
  security_groups = [module.api_gateway_security_group.security_group_id]

  security_group_rules = {
    ingress_all = {
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  target_groups = [
    {
      name_prefix      = "tg-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 65
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 60
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

  tags = {
    Environment = "cloud-studies"
  }
}

/* Cria uma IAM Role com Admin Permissions (default) */
module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.30.0"

  attach_admin_policy = true
  attach_poweruser_policy = true
  attach_readonly_policy = true
  role_requires_mfa = false

  role_name = "ecs-cluster-role"
  role_description = "IAM Role para cloud studies"

  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  trusted_role_actions = [
    "sts:AssumeRole",
    "sts:TagSession",
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:GetRepositoryPolicy",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:DescribeImages",
    "ecr:BatchGetImage",
    "ecr:GetLifecyclePolicy",
    "ecr:GetLifecyclePolicyPreview",
    "ecr:ListTagsForResource",
    "ecr:DescribeImageScanFindings"
  ]

  trusted_role_arns = [
    "arn:aws:iam::163305182511:root",
    "arn:aws:iam::163305182511:user/iac_user",
    "arn:aws:iam::163305182511:role/ecs-cluster-role"
  ]

  tags = {
    Environment = "cloud-studies"
  }
}

/* Cria um Cluster ECS */
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.2"

  cluster_name = "ecs-cluster-cloud-studies"
  task_exec_iam_role_name = module.iam_assumable_role.iam_role_name
  task_exec_iam_role_path = module.iam_assumable_role.iam_role_path

  tags = {
    Environment = "cloud-studies"
  }

}

/* Cria um Service ECS no cluster, as subnets, a role e o load balancer criado anteriormente */
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.2"

  depends_on = [module.iam_assumable_role]

  assign_public_ip = true
  name = "ecs-service-cloud-studies-2"
  family = "family-cloud-studies"
  cluster_arn = module.ecs_cluster.arn
  subnet_ids = module.main_vpc.public_subnet_ids

  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress_all = {
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  /*
  create_iam_role         = false
  create_tasks_iam_role   = false
  create_task_exec_policy = false
  */

  iam_role_arn            = module.iam_assumable_role.iam_role_arn
  tasks_iam_role_arn      = module.iam_assumable_role.iam_role_arn
  task_exec_iam_role_arn  = module.iam_assumable_role.iam_role_arn

  container_definitions = {
    ecs-service-cloud-studies = {
    //  cpu       = 2
     // memory    = 6
      essential = true
      image     = "public.ecr.aws/nginx/nginx:latest"
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

  tags = {
    Environment = "cloud-studies"
  }
}

/* Cria um security group para ser usado no API Gateway que será criado */
module "api_gateway_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "apigw-cloud-studies"
  description = "API Gateway group for example usage"
  vpc_id      = module.main_vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  egress_rules = ["all-all"]

  tags = {
    Environment = "cloud-studies"
  }
}

/* Cria um API Gateway para acessar o cluster ECS via VPC Link */
module "apigateway-v2" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name          = "apigw-cloud-studies"
  description   = "API Gateway for cloud studies"
  protocol_type = "HTTP"


  create_api_domain_name = false

  default_stage_access_log_format = "{ 'requestId':'$context.requestId', 'ip': '$context.identity.sourceIp', 'requestTime':'$context.requestTime', 'httpMethod':'$context.httpMethod','routeKey':'$context.routeKey', 'status':'$context.status','protocol':'$context.protocol', 'errorResponeType': '$context.error.responseType', 'responseLength':'$context.responseLength' , 'authorizerError':'$context.authorizer.error', 'errorMessage':'$context.error.message', 'msgString':'$context.error.messageString'}"
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
      security_group_ids = [module.api_gateway_security_group.security_group_id]
      subnet_ids         = module.main_vpc.public_subnet_ids
    }
  }

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  tags = {
    Environment = "cloud-studies"
  }

}

module "cloudwatch_log-group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "4.3.0"

  name = "apigw-log-group"
  retention_in_days = 1

  tags = {
    Environment = "cloud-studies"
  }

}

/*
module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = "s3-bkt-cloud-studies"
  allowed_kms_key_arn = module.kms.key_arn

  tags = {
    Environment = "cloud-studies"
  }
}

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


<END OF NEW TESTES>
*/

/*
module "private_eks_cluster" {
  source  = "./modules/eks-cluster"

  vpc_id = module.main_vpc.vpc_id
  cluster_name = "private-eks-cluster"
  k8s_subnet_ids = module.main_vpc.private_subnet_ids

}
*/

/*
module "public_eks_cluster" {
  source  = "./modules/eks-cluster"

  vpc_id         = module.main_vpc.vpc_id
  cluster_name   = "public-eks-cluster"
  k8s_subnet_ids = module.main_vpc.public_subnet_ids

}
*/
/*
module ecs_cluster {
  source = "./modules/ecs-cluster"
  vpc_id = module.main_vpc.vpc_id
}

module "msk_cluster" {
  source = "./modules/msk-cluster"

  vpc_id                  = module.main_vpc.vpc_id
  msk_kafka_subnet_ids    = module.main_vpc.intra_subnet_ids
  msk_kafka_cluster_name  = var.msk_kafka_cluster_name
  msk_kafka_version       = var.msk_kafka_version
  msk_kafka_instance_type = var.msk_kafka_instance_type

}

module "public_application_load_balancer" {
  source = "./modules/application-load-balancer"

  vpc_id     = module.main_vpc.vpc_id
  subnet_ids = module.main_vpc.public_subnet_ids
}
*/
/*
module "network_load_balancer" {
  source = "./modules/elastic-load-balancer"

  vpc_id             = module.main_vpc.vpc_id
  subnet_ids         = module.main_vpc.public_subnet_ids
  security_group_ids = module.apigateway.api_gateway_security_group_ids
}

module "apigateway" {
  source  = "./modules/api-gateway"

  nlb_http_tcp_listener_arn = module.network_load_balancer.nlb_http_tcp_listener_arns
  vpc_id                    = module.main_vpc.vpc_id
  subnet_ids                = module.main_vpc.public_subnet_ids
}
*/