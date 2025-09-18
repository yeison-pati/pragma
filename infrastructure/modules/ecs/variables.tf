variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnets for the ECS tasks"
  type        = list(string)
}

variable "user_service_image_url" {
  description = "The ECR image URL for the user-service"
  type        = string
}

variable "order_service_image_url" {
  description = "The ECR image URL for the order-service"
  type        = string
}

variable "user_service_target_group_arn" {
  description = "The ARN of the ALB target group for the user-service"
  type        = string
}

variable "order_service_target_group_arn" {
  description = "The ARN of the ALB target group for the order-service"
  type        = string
}

variable "redis_host" {
  description = "The hostname of the Redis cache."
  type        = string
}

variable "redis_port" {
  description = "The port for the Redis cache."
  type        = number
}

variable "kafka_bootstrap_servers" {
  description = "The comma-separated list of Kafka bootstrap servers."
  type        = string
}

variable "container_cpu" {
  description = "The CPU units to allocate for each container"
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "container_memory" {
  description = "The memory (in MiB) to allocate for each container"
  type        = number
  default     = 512 # 0.5 GB
}

variable "rds_endpoint" {
  description = "The endpoint of the RDS database"
  type        = string
}

variable "rds_db_name" {
  description = "The name of the RDS database"
  type        = string
}

variable "rds_username" {
  description = "The username for the RDS database"
  type        = string
}

variable "rds_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "mongo_uri" {
  description = "MongoDB connection string for Order Service"
  type        = string
}
