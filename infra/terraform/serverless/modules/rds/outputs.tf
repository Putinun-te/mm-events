output "db_instance_identifier" {
  description = "Identifier for the DB instance."
  value       = aws_db_instance.this.id
}

output "endpoint" {
  description = "Database endpoint."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "security_group_id" {
  description = "Security group protecting the database."
  value       = aws_security_group.db.id
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing credentials."
  value       = aws_secretsmanager_secret.credentials.arn
}
