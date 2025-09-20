output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "user_service_url" {
  description = "User Service URL"
  value       = "http://${aws_lb.main.dns_name}/users"
}

output "order_service_url" {
  description = "Order Service URL"
  value       = "http://${aws_lb.main.dns_name}/orders"
}

output "auth_url" {
  description = "Auth URL"
  value       = "http://${aws_lb.main.dns_name}/auth"
}