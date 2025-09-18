output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of the IAM role for ECS task execution"
  value       = aws_iam_role.ecs_task_execution_role.arn
}
