output "environment_url" {
    description = "The URL of the ALB"
    value = module.blog_alb.lb_dns_name
}