output "endpoint" {
  description = "The endpoint of the RDS instance."
  value       = aws_db_instance.default.endpoint
}

output "db_name" {
  description = "The name of the database."
  value       = aws_db_instance.default.db_name
}

output "username" {
  description = "The username for the database."
  value       = aws_db_instance.default.username
  sensitive   = true
}

output "password" {
  description = "The password for the database."
  value       = aws_db_instance.default.password
  sensitive   = true
}
