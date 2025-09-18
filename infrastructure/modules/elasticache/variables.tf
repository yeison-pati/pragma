variable "project_name" {
  description = "The name of the project, used to prefix resource names."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ElastiCache cluster will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the ElastiCache subnet group."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The ID of the security group for the ECS tasks, to allow access to Redis."
  type        = string
}
