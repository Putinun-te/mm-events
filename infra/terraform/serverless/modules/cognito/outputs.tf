output "user_pool_id" {
  description = "ID of the user pool."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the user pool."
  value       = aws_cognito_user_pool.this.arn
}

output "app_client_id" {
  description = "Client ID for the user pool app client."
  value       = aws_cognito_user_pool_client.this.id
}

output "domain" {
  description = "Cognito hosted domain."
  value       = length(aws_cognito_user_pool_domain.this) == 0 ? null : aws_cognito_user_pool_domain.this[0].domain
}
