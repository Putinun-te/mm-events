output "cache_arn" {
  description = "ARN of the serverless cache."
  value       = aws_elasticache_serverless_cache.this.arn
}

output "endpoint_address" {
  description = "Primary endpoint address."
  value       = aws_elasticache_serverless_cache.this.endpoint[0].address
}

output "endpoint_port" {
  description = "Port for the cache endpoint."
  value       = aws_elasticache_serverless_cache.this.endpoint[0].port
}

output "security_group_id" {
  description = "Security group protecting the cache."
  value       = aws_security_group.cache.id
}
