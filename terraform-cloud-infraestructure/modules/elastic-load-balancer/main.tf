
module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.6.1"

  name               = "dev-nlb"
  load_balancer_type = "network"

  vpc_id          = var.vpc_id
  subnets         = var.subnet_ids
  security_groups = var.security_group_ids

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
      action_type        = "forward"
    }
  ]
/*
  target_groups = [
    {
      name_prefix      = "bkd"
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]*/

}