# AWS Infrastructure for Microservices

This Terraform configuration deploys a complete microservices architecture on AWS using ECS Fargate.

## Architecture

- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **ALB**: Application Load Balancer for routing traffic
- **ECS Fargate**: Serverless container platform
- **RDS PostgreSQL**: Managed database for user-service
- **Service Discovery**: AWS Cloud Map for internal service communication

## Services Deployed

1. **Redis**: In-memory cache
2. **MongoDB**: NoSQL database for order-service
3. **Kafka + Zookeeper**: Message broker for event-driven communication
4. **User Service**: Spring Boot application (port 8081)
5. **Order Service**: Spring WebFlux application (port 8082)

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Docker images pushed to Docker Hub

## Deployment

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values

3. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Key Improvements

- **Simplified Architecture**: Single main.tf file for easier management
- **Proper Networking**: Correct security groups and subnet configurations
- **Service Dependencies**: Proper dependency ordering for container startup
- **Health Checks**: Configured health checks for all services
- **Service Discovery**: AWS Cloud Map for internal service communication
- **Logging**: CloudWatch logs for all services

## Accessing the Application

After deployment, use the ALB DNS name from the outputs:

- User Service: `http://<alb-dns>/users`
- Order Service: `http://<alb-dns>/orders`
- Authentication: `http://<alb-dns>/auth`

## Cleanup

```bash
terraform destroy
```