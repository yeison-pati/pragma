# Generate random credentials for the database
resource "random_string" "username" {
  length  = 8
  special = false
  upper   = false
}

resource "random_password" "password" {
  length  = 16
  special = false
}

# DocumentDB Subnet Group
resource "aws_docdb_subnet_group" "default" {
  name       = "${var.project_name}-docdb-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-docdb-subnet-group"
  }
}

# DocumentDB Security Group
resource "aws_security_group" "docdb" {
  name        = "${var.project_name}-docdb-sg"
  description = "Allow traffic to the DocumentDB cluster"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from the ECS tasks security group on the DocumentDB port
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-docdb-sg"
  }
}

# DocumentDB Cluster
resource "aws_docdb_cluster" "default" {
  cluster_identifier      = "${var.project_name}-docdb-cluster"
  engine                  = "docdb"
  engine_version          = "4.0.0"
  master_username         = random_string.username.result
  master_password         = random_password.password.result
  db_subnet_group_name    = aws_docdb_subnet_group.default.name
  vpc_security_group_ids  = [aws_security_group.docdb.id]
  skip_final_snapshot     = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.default.name

  tags = {
    Name = "${var.project_name}-docdb-cluster"
  }
}

# DocumentDB requires a parameter group to enable TLS
resource "aws_docdb_cluster_parameter_group" "default" {
  family = "docdb4.0"
  name   = "${var.project_name}-docdb-pg"

  parameter {
    name  = "tls"
    value = "enabled"
  }
}

# DocumentDB Cluster Instance
resource "aws_docdb_cluster_instance" "default" {
  count              = 1
  identifier         = "${var.project_name}-docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.default.id
  instance_class     = "db.t3.medium"
}
