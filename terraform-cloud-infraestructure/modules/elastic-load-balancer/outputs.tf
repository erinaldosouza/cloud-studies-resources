
output "nlb_http_tcp_listener_arns" {
  description = "ALB HTTP Listener ARM"
  value       = module.nlb.http_tcp_listener_arns
}