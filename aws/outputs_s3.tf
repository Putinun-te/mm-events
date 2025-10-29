output "frontend_s3_bucket_name" {
  description = "Name of the S3 bucket used to host the frontend"
  value       = aws_s3_bucket.frontend_site.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "frontend_cdn_id" {
  description = "CloudFront distribution ID for the frontend"
  value       = aws_cloudfront_distribution.frontend_cdn.id
}
