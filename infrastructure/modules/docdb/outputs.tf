output "endpoint" {
  description = "The endpoint of the DocumentDB cluster."
  value       = aws_docdb_cluster.default.endpoint
}

output "port" {
  description = "The port of the DocumentDB cluster."
  value       = aws_docdb_cluster.default.port
}

output "username" {
  description = "The username for the DocumentDB cluster."
  value       = aws_docdb_cluster.default.master_username
  sensitive   = true
}

output "password" {
  description = "The password for the DocumentDB cluster."
  value       = aws_docdb_cluster.default.master_password
  sensitive   = true
}

output "connection_string" {
  description = "The full connection string for the DocumentDB cluster."
  value = format(
    "mongodb://%s:%s@%s:%s/%s?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false",
    urlencode(aws_docdb_cluster.default.master_username),
    urlencode(aws_docdb_cluster.default.master_password),
    aws_docdb_cluster.default.endpoint,
    aws_docdb_cluster.default.port,
    var.db_name
  )
  sensitive = true
}
