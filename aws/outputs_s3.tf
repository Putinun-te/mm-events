output "frontend_s3_bucket_name" {
  description = "Name of the S3 bucket used to host the frontend"
  value       = aws_s3_bucket.frontend_site.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (or S3 website endpoint if CloudFront is disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.frontend_cdn[0].domain_name : "http://${aws_s3_bucket.frontend_site.website_endpoint}"
}

output "frontend_cdn_id" {
  description = "CloudFront distribution ID for the frontend"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.frontend_cdn[0].id : "CloudFront not enabled"
}

output "s3_website_endpoint" {
  description = "S3 website endpoint for direct access"
  value       = "http://${aws_s3_bucket.frontend_site.website_endpoint}"
}
