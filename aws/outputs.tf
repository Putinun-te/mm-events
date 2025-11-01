output "rds_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}

# Cognito outputs moved to cognito_web_integration.tf

output "s3_event_pictures" {
  value = aws_s3_bucket.event_pictures.id
}

output "s3_user_avatars" {
  value = aws_s3_bucket.user_avatars.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

