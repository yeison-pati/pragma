output "user_service_target_group_arn" {
  description = "The ARN of the User Service target group"
  value       = aws_lb_target_group.user_service.arn
}

output "order_service_target_group_arn" {
  description = "The ARN of the Order Service target group"
  value       = aws_lb_target_group.order_service.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}
