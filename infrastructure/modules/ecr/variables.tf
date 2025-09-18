variable "user_service_repo_name" {
  description = "Name for the User Service ECR repository"
  type        = string
  default     = "user-service"
}

variable "order_service_repo_name" {
  description = "Name for the Order Service ECR repository"
  type        = string
  default     = "order-service"
}
