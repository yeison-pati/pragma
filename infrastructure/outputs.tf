output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "The public URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "user_service_url" {
  description = "The URL for the User Service"
  value       = "http://${module.alb.alb_dns_name}/users"
}

output "order_service_url" {
  description = "The URL for the Order Service"
  value       = "http://${module.alb.alb_dns_name}/orders"
}

output "auth_url" {
  description = "The URL for Authentication"
  value       = "http://${module.alb.alb_dns_name}/auth"
}
