# Creates the ECR repository for the User Service
resource "aws_ecr_repository" "user_service" {
  name = var.user_service_repo_name

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Creates the ECR repository for the Order Service
resource "aws_ecr_repository" "order_service" {
  name = var.order_service_repo_name

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy to clean up old images in the User Service repository
resource "aws_ecr_lifecycle_policy" "user_service_policy" {
  repository = aws_ecr_repository.user_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 5 images",
      selection = {
        tagStatus     = "any",
        countType     = "imageCountMoreThan",
        countNumber   = 5
      },
      action = {
        type = "expire"
      }
    }]
  })
}

# Lifecycle policy to clean up old images in the Order Service repository
resource "aws_ecr_lifecycle_policy" "order_service_policy" {
  repository = aws_ecr_repository.order_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 5 images",
      selection = {
        tagStatus     = "any",
        countType     = "imageCountMoreThan",
        countNumber   = 5
      },
      action = {
        type = "expire"
      }
    }]
  })
}
