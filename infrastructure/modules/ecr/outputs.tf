output "user_service_repository_url" {
  description = "The URL of the User Service ECR repository"
  value       = aws_ecr_repository.user_service.repository_url
}

output "order_service_repository_url" {
  description = "The URL of the Order Service ECR repository"
  value       = aws_ecr_repository.order_service.repository_url
}
