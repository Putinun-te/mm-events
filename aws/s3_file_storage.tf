# S3 Buckets for File Storage
resource "aws_s3_bucket" "event_pictures" {
  bucket = "${var.project_name}-event-pictures-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "Concert Event Pictures"
    Environment = var.environment
    Purpose     = "Store event images"
  }
}

resource "aws_s3_bucket" "user_avatars" {
  bucket = "${var.project_name}-user-avatars-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "Concert User Avatars"
    Environment = var.environment
    Purpose     = "Store user profile pictures"
  }
}

# Enable versioning for event pictures
resource "aws_s3_bucket_versioning" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access initially, allow only via CloudFront
resource "aws_s3_bucket_public_access_block" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Server-side encryption for event pictures
resource "aws_s3_bucket_server_side_encryption_configuration" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Server-side encryption for user avatars
resource "aws_s3_bucket_server_side_encryption_configuration" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CORS configuration for event pictures
resource "aws_s3_bucket_cors_configuration" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = [
      "https://${var.frontend_domain}",
      "http://localhost:3000"  # Development
    ]
    expose_headers = ["ETag", "x-amz-version-id"]
    max_age_seconds = 3000
  }
}

# CORS configuration for user avatars
resource "aws_s3_bucket_cors_configuration" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = [
      "https://${var.frontend_domain}",
      "http://localhost:3000"  # Development
    ]
    expose_headers = ["ETag", "x-amz-version-id"]
    max_age_seconds = 3000
  }
}

# Bucket policy for event pictures - allow public read
resource "aws_s3_bucket_policy" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PublicRead"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.event_pictures.arn}/*"
      },
      {
        Sid    = "BackendWrite"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.backend_ec2_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.event_pictures.arn}/*"
      }
    ]
  })
}

# Bucket policy for user avatars - allow public read
resource "aws_s3_bucket_policy" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PublicRead"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.user_avatars.arn}/*"
      },
      {
        Sid    = "BackendWrite"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.backend_ec2_role.arn
        }
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.user_avatars.arn}/*"
      }
    ]
  })
}

# Lifecycle policy for event pictures - archive to Glacier after 1 year
resource "aws_s3_bucket_lifecycle_configuration" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  rule {
    id     = "archive-old-pictures"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }
}

# Lifecycle policy for user avatars - delete after 5 years
resource "aws_s3_bucket_lifecycle_configuration" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  rule {
    id     = "delete-old-avatars"
    status = "Enabled"

    expiration {
      days = 1825  # 5 years
    }
  }
}

# Output bucket names and ARNs
output "event_pictures_bucket_name" {
  value       = aws_s3_bucket.event_pictures.id
  description = "Name of the S3 bucket for event pictures"
}

output "event_pictures_bucket_arn" {
  value       = aws_s3_bucket.event_pictures.arn
  description = "ARN of the event pictures bucket"
}

output "user_avatars_bucket_name" {
  value       = aws_s3_bucket.user_avatars.id
  description = "Name of the S3 bucket for user avatars"
}

output "user_avatars_bucket_arn" {
  value       = aws_s3_bucket.user_avatars.arn
  description = "ARN of the user avatars bucket"
}

output "event_pictures_bucket_region_domain_name" {
  value       = aws_s3_bucket.event_pictures.bucket_regional_domain_name
  description = "Regional domain name of event pictures bucket"
}

output "user_avatars_bucket_region_domain_name" {
  value       = aws_s3_bucket.user_avatars.bucket_regional_domain_name
  description = "Regional domain name of user avatars bucket"
}
