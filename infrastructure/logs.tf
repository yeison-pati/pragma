# CloudWatch Log Groups for ECS Services
resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/redis"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "kafka" {
  name              = "/ecs/kafka"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/user-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/order-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mongodb" {
  name              = "/ecs/mongodb"
  retention_in_days = 7
}