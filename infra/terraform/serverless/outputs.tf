output "api_endpoint" {
  description = "Base URL for the HTTP API."
  value       = module.lambda_api.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name."
  value       = module.lambda_api.function_name
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID."
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito app client ID."
  value       = module.cognito.app_client_id
}

output "s3_bucket_name" {
  description = "S3 bucket for file uploads."
  value       = module.s3.bucket_name
}

output "rds_endpoint" {
  description = "RDS endpoint hostname."
  value       = module.rds.endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN with database credentials."
  value       = module.rds.secret_arn
}

output "efs_access_point_arn" {
  description = "EFS access point ARN."
  value       = module.efs.access_point_arn
}

output "redis_endpoint" {
  description = "Redis endpoint (hostname:port) when ElastiCache is enabled."
  value       = var.enable_elasticache ? format("%s:%s", module.elasticache[0].endpoint_address, module.elasticache[0].endpoint_port) : null
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard if created."
  value       = var.enable_cloudwatch_alarms && var.enable_cloudwatch_dashboard ? module.cloudwatch[0].dashboard_name : null
}
