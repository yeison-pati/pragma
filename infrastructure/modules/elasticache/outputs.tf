output "redis_primary_endpoint_address" {
  description = "The address of the primary endpoint for the Redis cluster."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "The port for the Redis cluster."
  value       = aws_elasticache_cluster.redis.port
}
