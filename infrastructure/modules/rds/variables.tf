variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the database."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The security group ID of the ECS tasks to allow traffic from."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "interview_project_db"
}

variable "db_username" {
  description = "The username for the database."
  type        = string
}

variable "db_password" {
  description = "The password for the database."
  type        = string
  sensitive   = true
}
