output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}
