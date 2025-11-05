output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN for the Lambda function."
  value       = aws_lambda_function.this.invoke_arn
}

output "api_endpoint" {
  description = "Invoke URL for the HTTP API stage."
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "api_id" {
  description = "ID of the HTTP API."
  value       = aws_apigatewayv2_api.http.id
}

output "log_group_name" {
  description = "CloudWatch log group for Lambda."
  value       = aws_cloudwatch_log_group.lambda.name
}
