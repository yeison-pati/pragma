# Security group for the MSK cluster
resource "aws_security_group" "msk_sg" {
  name        = "${var.project_name}-msk-sg"
  description = "Allow inbound traffic from ECS tasks to MSK brokers"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from the ECS tasks
  ingress {
    description     = "Kafka plaintext from ECS"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  ingress {
    description     = "Kafka TLS from ECS"
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-msk-sg"
  }
}

# MSK Cluster
resource "aws_msk_cluster" "kafka_cluster" {
  cluster_name           = "${var.project_name}-kafka-cluster"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = 2 # Minimum for a multi-AZ setup for basic availability

  lifecycle {
    replace_triggered_by = [aws_msk_cluster.kafka_cluster.client_authentication]
  }

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = var.private_subnet_ids
    security_groups = [aws_security_group.msk_sg.id]
    storage_info {
      ebs_storage_info {
        volume_size = 10 # GiB
      }
    }
  }

  client_authentication {
    sasl {
      scram = true
    }
    tls {
      certificate_authority_arns = []
    }
    unauthenticated = false
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  tags = {
    Name = "${var.project_name}-kafka-cluster"
  }
}
