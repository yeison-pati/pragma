# Data source to get the list of availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# ----------------------------------------------------------------
# VPC Module
# ----------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = data.aws_availability_zones.available.names
}

# ----------------------------------------------------------------
# Security Groups
# ----------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP traffic from anywhere to the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------------------------------------------
# ALB Module
# ----------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnets     = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
}

# ----------------------------------------------------------------
# RDS Module
# ----------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = aws_security_group.ecs_tasks.id
  db_username           = var.postgres_username
  db_password           = var.postgres_password
}

# ----------------------------------------------------------------
# Service Discovery
# ----------------------------------------------------------------
resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "${var.project_name}.local"
  vpc  = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "redis" {
  name = "redis"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_service_discovery_service" "kafka" {
  name = "kafka"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_service_discovery_service" "mongodb" {
  name = "mongodb"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

# ----------------------------------------------------------------
# ECS Cluster
# ----------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

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

# ----------------------------------------------------------------
# Redis Service
# ----------------------------------------------------------------
resource "aws_ecs_task_definition" "redis" {
  family                   = "redis"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "redis"
    image     = "redis:7-alpine"
    essential = true
    portMappings = [{
      containerPort = 6379
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/redis"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnet_ids
    assign_public_ip = false
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }
}

# ----------------------------------------------------------------
# Kafka Service
# ----------------------------------------------------------------
resource "aws_ecs_task_definition" "kafka" {
  family                   = "kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "kafka"
    image     = "confluentinc/cp-kafka:latest"
    essential = true
    portMappings = [{
      containerPort = 9092
    }]
    environment = [
      { name = "KAFKA_BROKER_ID", value = "1" },
      { name = "KAFKA_ZOOKEEPER_CONNECT", value = "localhost:2181" },
      { name = "KAFKA_ADVERTISED_LISTENERS", value = "PLAINTEXT://localhost:9092" },
      { name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR", value = "1" },
      { name = "KAFKA_PROCESS_ROLES", value = "broker" },
      { name = "KAFKA_CONTROLLER_QUORUM_VOTERS", value = "" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/kafka"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }, {
    name      = "zookeeper"
    image     = "confluentinc/cp-zookeeper:latest"
    essential = true
    portMappings = [{
      containerPort = 2181
    }]
    environment = [
      { name = "ZOOKEEPER_CLIENT_PORT", value = "2181" },
      { name = "ZOOKEEPER_TICK_TIME", value = "2000" }
    ]
  }])
}

resource "aws_ecs_service" "kafka" {
  name            = "kafka"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.kafka.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnet_ids
    assign_public_ip = false
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.kafka.arn
  }
}

# ----------------------------------------------------------------
# MongoDB Service
# ----------------------------------------------------------------
resource "aws_ecs_task_definition" "mongodb" {
  family                   = "mongodb"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "mongodb"
    image     = "mongo:7"
    essential = true
    portMappings = [{
      containerPort = 27017
    }]
    environment = [
      { name = "MONGO_INITDB_ROOT_USERNAME", value = var.mongodb_username },
      { name = "MONGO_INITDB_ROOT_PASSWORD", value = var.mongodb_password }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/mongodb"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "mongodb" {
  name            = "mongodb"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.mongodb.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnet_ids
    assign_public_ip = false
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mongodb.arn
  }
}

# ----------------------------------------------------------------
# User Service
# ----------------------------------------------------------------
resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "user-service"
    image     = "${var.docker_username}/user-service:latest"
    essential = true
    portMappings = [{
      containerPort = 8081
    }]
    environment = [
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${module.rds.endpoint}/${module.rds.db_name}" },
      { name = "SPRING_DATASOURCE_USERNAME", value = var.postgres_username },
      { name = "SPRING_DATASOURCE_PASSWORD", value = var.postgres_password },
      { name = "SPRING_DATA_REDIS_HOST", value = "redis.${var.project_name}.local" },
      { name = "SPRING_DATA_REDIS_PORT", value = tostring(var.redis_port) },
      { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "kafka.${var.project_name}.local:${var.kafka_port}" },
      { name = "APPLICATION_SECURITY_JWT_SECRET_KEY", value = var.jwt_secret_key }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/user-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnet_ids
    assign_public_ip = false
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = module.alb.user_service_target_group_arn
    container_name   = "user-service"
    container_port   = 8081
  }

  depends_on = [aws_iam_role.ecs_task_execution_role]
}

# ----------------------------------------------------------------
# Order Service
# ----------------------------------------------------------------
resource "aws_ecs_task_definition" "order_service" {
  family                   = "order-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "order-service"
    image     = "${var.docker_username}/order-service:latest"
    essential = true
    portMappings = [{
      containerPort = 8082
    }]
    environment = [
      { name = "SPRING_DATA_MONGODB_URI", value = "mongodb://${var.mongodb_username}:${var.mongodb_password}@mongodb.${var.project_name}.local:${var.mongodb_port}/orders?authSource=admin" },
      { name = "SPRING_DATA_REDIS_HOST", value = "redis.${var.project_name}.local" },
      { name = "SPRING_DATA_REDIS_PORT", value = tostring(var.redis_port) },
      { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = "kafka.${var.project_name}.local:${var.kafka_port}" },
      { name = "APPLICATION_SECURITY_JWT_SECRET_KEY", value = var.jwt_secret_key }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/order-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnet_ids
    assign_public_ip = false
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = module.alb.order_service_target_group_arn
    container_name   = "order-service"
    container_port   = 8082
  }

  depends_on = [aws_iam_role.ecs_task_execution_role]
}