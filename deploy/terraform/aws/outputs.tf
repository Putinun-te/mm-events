output "frontend_url" {
  description = "Public URL of the site (CloudFront)."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "api_base_url" {
  description = "Base URL of the API, used as NUXT_PUBLIC_BACKEND_BASE_URL. Same origin as the site; the app calls <this>/api/..."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "health_url" {
  description = "Backend health check through CloudFront."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}/actuator/health"
}

output "ecr_repository_url" {
  description = "Push the backend image here."
  value       = aws_ecr_repository.backend.repository_url
}

output "site_bucket" {
  description = "S3 bucket for the static frontend files."
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "Distribution to invalidate after uploading the frontend."
  value       = aws_cloudfront_distribution.site.id
}

output "ecs_cluster" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service" {
  description = "ECS service name."
  value       = aws_ecs_service.backend.name
}

output "log_group" {
  description = "CloudWatch log group of the backend."
  value       = aws_cloudwatch_log_group.backend.name
}

output "db_endpoint" {
  description = "RDS endpoint (private; reachable from the VPC only)."
  value       = aws_db_instance.mysql.address
}

output "db_password_secret_arn" {
  description = "Secrets Manager secret holding the RDS master password (created by RDS)."
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}
