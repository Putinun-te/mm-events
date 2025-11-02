# ============================================================================
# FRONTEND WEB APPLICATION BUCKET
# ============================================================================
resource "aws_s3_bucket" "dev_frontend" {
  bucket = "${var.project_name}-dev-frontend-${substr(md5("${var.project_name}-frontend"), 0, 8)}"
  
  tags = {
    Name        = "${var.project_name}-frontend"
    Purpose     = "Frontend web application hosting"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "dev_frontend" {
  bucket = aws_s3_bucket.dev_frontend.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dev_frontend" {
  bucket = aws_s3_bucket.dev_frontend.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Configure bucket as static website hosting
resource "aws_s3_bucket_website_configuration" "dev_frontend" {
  bucket = aws_s3_bucket.dev_frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # For SPA routing
  }
}

# CORS configuration for frontend assets
resource "aws_s3_bucket_cors_configuration" "dev_frontend" {
  bucket = aws_s3_bucket.dev_frontend.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Bucket policy to allow public read access for static website
resource "aws_s3_bucket_policy" "dev_frontend" {
  bucket = aws_s3_bucket.dev_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dev_frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.dev_frontend]
}

# ============================================================================
# EVENT PICTURES BUCKET
# ============================================================================
resource "aws_s3_bucket" "event_pictures" {
  bucket = "${var.project_name}-event-pictures-useast1-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "${var.project_name}-event-pictures"
  }
}

resource "aws_s3_bucket_versioning" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration for event pictures
resource "aws_s3_bucket_cors_configuration" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ============================================================================
# USER AVATARS BUCKET
# ============================================================================
resource "aws_s3_bucket" "user_avatars" {
  bucket = "${var.project_name}-user-avatars-useast1-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "${var.project_name}-user-avatars"
  }
}

resource "aws_s3_bucket_versioning" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration for user avatars
resource "aws_s3_bucket_cors_configuration" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ============================================================================
# S3 OUTPUTS
# ============================================================================
output "frontend_bucket_name" {
  value       = aws_s3_bucket.dev_frontend.id
  description = "Frontend S3 bucket name"
}

output "frontend_bucket_arn" {
  value       = aws_s3_bucket.dev_frontend.arn
  description = "Frontend S3 bucket ARN"
}

output "event_pictures_bucket_name" {
  value       = aws_s3_bucket.event_pictures.id
  description = "Event pictures S3 bucket name"
}

output "user_avatars_bucket_name" {
  value       = aws_s3_bucket.user_avatars.id
  description = "User avatars S3 bucket name"
}
