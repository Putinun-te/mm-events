output "api_endpoint" {
  description = "API Gateway HTTPS endpoint (TLS included by default)"
  value       = module.serverless.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  value       = module.serverless.cognito_user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito app client ID"
  value       = module.serverless.cognito_app_client_id
}

output "s3_bucket_name" {
  description = "S3 bucket for file uploads"
  value       = module.serverless.s3_bucket_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.serverless.rds_endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = module.serverless.rds_secret_arn
}

output "redis_endpoint" {
  description = "Redis endpoint (if enabled)"
  value       = module.serverless.redis_endpoint
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.serverless.cloudwatch_dashboard_name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.serverless.lambda_function_name
}

output "efs_access_point_arn" {
  description = "EFS access point ARN for event/avatar pictures"
  value       = module.serverless.efs_access_point_arn
}
