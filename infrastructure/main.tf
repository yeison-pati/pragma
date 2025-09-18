# Data source to get the list of availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# ----------------------------------------------------------------
# VPC Module (No changes needed here)
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
# Security Groups (Refactored for ECS)
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

  # Allow inbound traffic from the ALB on any port (ECS will map them)
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound traffic so tasks can pull images and talk to other AWS services
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ----------------------------------------------------------------
# ECR Module (New)
# ----------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"
  # Using default repository names: "user-service" and "order-service"
}


# ----------------------------------------------------------------
# ALB Module (Refactored)
# ----------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnets     = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
}


# ----------------------------------------------------------------
# ElastiCache Module (Redis)
# ----------------------------------------------------------------
module "elasticache" {
  source = "./modules/elasticache"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = aws_security_group.ecs_tasks.id
}


# ----------------------------------------------------------------
# Database Modules (RDS and DocumentDB)
# ----------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = aws_security_group.ecs_tasks.id
}

module "docdb" {
  source = "./modules/docdb"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = aws_security_group.ecs_tasks.id
}


# ----------------------------------------------------------------
# ECS Module (New)
# ----------------------------------------------------------------
module "msk" {
  source = "./modules/msk"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = aws_security_group.ecs_tasks.id
}

module "ecs" {
  source = "./modules/ecs"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  private_subnets   = module.vpc.private_subnet_ids
  
  user_service_image_url  = "${module.ecr.user_service_repository_url}:latest"
  order_service_image_url = "${module.ecr.order_service_repository_url}:latest"
  
  user_service_target_group_arn  = module.alb.user_service_target_group_arn
  order_service_target_group_arn = module.alb.order_service_target_group_arn
  
  redis_host = module.elasticache.redis_primary_endpoint_address
  redis_port = module.elasticache.redis_port

  kafka_bootstrap_servers = module.msk.kafka_bootstrap_brokers_tls

  
  rds_endpoint = module.rds.endpoint
  rds_db_name  = module.rds.db_name
  rds_username = module.rds.username
  rds_password = module.rds.password
  
  mongo_uri = module.docdb.connection_string
}
