# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Definition for User Service
resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "user-service"
    image     = var.user_service_image_url
    essential = true
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
    }]
    environment = [
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${var.rds_endpoint}/${var.rds_db_name}" },
      { name = "SPRING_DATASOURCE_USERNAME", value = var.rds_username },
      { name = "SPRING_DATASOURCE_PASSWORD", value = var.rds_password },
      { name = "SPRING_DATA_REDIS_HOST", value = var.redis_host },
      { name = "SPRING_DATA_REDIS_PORT", value = tostring(var.redis_port) },
      { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.kafka_bootstrap_servers }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/user-service"
        "awslogs-region"        = "us-east-1" # Or your region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# Task Definition for Order Service
resource "aws_ecs_task_definition" "order_service" {
  family                   = "order-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "order-service"
    image     = var.order_service_image_url
    essential = true
    portMappings = [{
      containerPort = 8082
      hostPort      = 8082
    }]
    environment = [
      { name = "SPRING_DATA_MONGODB_URI", value = var.mongo_uri },
      { name = "SPRING_DATA_REDIS_HOST", value = var.redis_host },
      { name = "SPRING_DATA_REDIS_PORT", value = tostring(var.redis_port) },
      { name = "KAFKA_BOOTSTRAP_SERVERS", value = var.kafka_bootstrap_servers }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/order-service"
        "awslogs-region"        = "us-east-1" # Or your region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service for User Service
resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    assign_public_ip = false
    security_groups = [] # Will be added later
  }

  load_balancer {
    target_group_arn = var.user_service_target_group_arn
    container_name   = "user-service"
    container_port   = 8081
  }

  depends_on = [aws_iam_role.ecs_task_execution_role]
}

# ECS Service for Order Service
resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    assign_public_ip = false
    security_groups = [] # Will be added later
  }

  load_balancer {
    target_group_arn = var.order_service_target_group_arn
    container_name   = "order-service"
    container_port   = 8082
  }

  depends_on = [aws_iam_role.ecs_task_execution_role]
}
