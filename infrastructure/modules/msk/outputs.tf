output "kafka_bootstrap_brokers_tls" {
  description = "The TLS connection string for the Kafka brokers."
  value       = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
}
