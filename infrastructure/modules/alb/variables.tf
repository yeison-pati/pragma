variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets for the ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs for the ALB"
  type        = list(string)
}
