output "alb_dns_name" {
  description = "The public DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "user_service_repository_url" {
  description = "The URL of the User Service ECR repository"
  value       = module.ecr.user_service_repository_url
}

output "order_service_repository_url" {
  description = "The URL of the Order Service ECR repository"
  value       = module.ecr.order_service_repository_url
}
