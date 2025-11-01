# ============================================================================
# OPTIMIZED CLOUDFRONT DISTRIBUTIONS
# Two separate distributions for better organization and performance:
# 1. User-Generated Content (UGC): Event pictures + User avatars
# 2. Static Website: Frontend application assets
# ============================================================================

# ============================================================================
# CLOUDFRONT ORIGIN ACCESS IDENTITY
# ============================================================================
resource "aws_cloudfront_origin_access_identity" "ugc_oai" {
  comment = "OAI for Concert User-Generated Content (Events + Avatars)"
}

resource "aws_cloudfront_origin_access_identity" "website_oai" {
  comment = "OAI for Concert Website Static Assets"
}

# ============================================================================
# S3 BUCKET FOR WEBSITE (Optional - for hosting frontend)
# ============================================================================
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-website-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Concert Website"
    Environment = var.environment
    Purpose     = "Host frontend static files"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # SPA routing
  }
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# ============================================================================
# CLOUDFRONT DISTRIBUTION #1: USER-GENERATED CONTENT (UGC)
# For: Event Pictures + User Avatars
# ============================================================================
resource "aws_cloudfront_distribution" "ugc" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Concert UGC CDN - Event Pictures & User Avatars"
  price_class         = "PriceClass_100" # North America + Europe only (cheaper)
  
  # Origin 1: Event Pictures
  origin {
    domain_name = aws_s3_bucket.event_pictures.bucket_regional_domain_name
    origin_id   = "S3-event-pictures"
    origin_path = "" # Serve from root
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.ugc_oai.cloudfront_access_identity_path
    }
  }

  # Origin 2: User Avatars
  origin {
    domain_name = aws_s3_bucket.user_avatars.bucket_regional_domain_name
    origin_id   = "S3-user-avatars"
    origin_path = ""
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.ugc_oai.cloudfront_access_identity_path
    }
  }

  # Default behavior: Event Pictures
  default_cache_behavior {
    target_origin_id       = "S3-event-pictures"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    # Optimal caching for images (rarely change)
    min_ttl     = 0
    default_ttl = 86400     # 1 day
    max_ttl     = 31536000  # 1 year
    
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
  }

  # Cache behavior for avatars: /avatars/*
  ordered_cache_behavior {
    path_pattern           = "/avatars/*"
    target_origin_id       = "S3-user-avatars"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    min_ttl     = 0
    default_ttl = 3600      # 1 hour (avatars change more often)
    max_ttl     = 86400     # 1 day
    
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.jpg" # Placeholder image
  }

  tags = {
    Name        = "Concert UGC CDN"
    Environment = var.environment
    Purpose     = "User-generated content delivery"
    FreeTier    = "true"
  }
}

# ============================================================================
# CLOUDFRONT DISTRIBUTION #2: WEBSITE (Static Assets)
# For: Frontend HTML, CSS, JS, Images
# ============================================================================
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Concert Website CDN - Frontend Static Assets"
  default_root_object = "index.html"
  price_class         = "PriceClass_All" # Global distribution for website
  
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-website"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    # Aggressive caching for static assets
    min_ttl     = 0
    default_ttl = 3600      # 1 hour for HTML
    max_ttl     = 31536000  # 1 year for versioned assets
    
    forwarded_values {
      query_string = true # Allow query strings for cache busting
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
  }

  # Cache behavior for static assets (CSS, JS, images)
  ordered_cache_behavior {
    path_pattern           = "/_nuxt/*" # Nuxt build assets
    target_origin_id       = "S3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    min_ttl     = 86400     # 1 day
    default_ttl = 604800    # 1 week
    max_ttl     = 31536000  # 1 year
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Cache behavior for images
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "S3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # SPA routing support
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  tags = {
    Name        = "Concert Website CDN"
    Environment = var.environment
    Purpose     = "Frontend application delivery"
    FreeTier    = "true"
  }
}

# ============================================================================
# S3 BUCKET POLICIES FOR CLOUDFRONT
# ============================================================================

# Event Pictures: CloudFront can READ, Lambda can WRITE
resource "aws_s3_bucket_policy" "event_pictures_cf" {
  bucket = aws_s3_bucket.event_pictures.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.ugc_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.event_pictures.arn}/*"
      },
      {
        Sid    = "AllowLambdaWrite"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_presigned_url_role.arn
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

  depends_on = [
    aws_cloudfront_origin_access_identity.ugc_oai,
    aws_s3_bucket_public_access_block.event_pictures
  ]
}

# User Avatars: CloudFront can READ, Lambda can WRITE
resource "aws_s3_bucket_policy" "user_avatars_cf" {
  bucket = aws_s3_bucket.user_avatars.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.ugc_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.user_avatars.arn}/*"
      },
      {
        Sid    = "AllowLambdaWrite"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_presigned_url_role.arn
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

  depends_on = [
    aws_cloudfront_origin_access_identity.ugc_oai,
    aws_s3_bucket_public_access_block.user_avatars
  ]
}

# Website: CloudFront READ only (deployed via CI/CD)
resource "aws_s3_bucket_policy" "website_cf" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_cloudfront_origin_access_identity.website_oai,
    aws_s3_bucket_public_access_block.website
  ]
}

# ============================================================================
# OUTPUTS
# ============================================================================

# UGC Distribution
output "cloudfront_ugc_id" {
  value       = aws_cloudfront_distribution.ugc.id
  description = "CloudFront distribution ID for user-generated content"
}

output "cloudfront_ugc_domain" {
  value       = aws_cloudfront_distribution.ugc.domain_name
  description = "CloudFront domain for UGC (use this for images)"
}

output "cloudfront_ugc_url" {
  value       = "https://${aws_cloudfront_distribution.ugc.domain_name}"
  description = "Full HTTPS URL for UGC CDN"
}

# Website Distribution
output "cloudfront_website_id" {
  value       = aws_cloudfront_distribution.website.id
  description = "CloudFront distribution ID for website"
}

output "cloudfront_website_domain" {
  value       = aws_cloudfront_distribution.website.domain_name
  description = "CloudFront domain for website (use this for frontend)"
}

output "cloudfront_website_url" {
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
  description = "Full HTTPS URL for website CDN"
}

# S3 Buckets
output "website_bucket_name" {
  value       = aws_s3_bucket.website.id
  description = "Website S3 bucket name (upload frontend build here)"
}

# Usage Examples
output "usage_examples" {
  value = {
    event_picture_url = "https://${aws_cloudfront_distribution.ugc.domain_name}/events/event123.jpg"
    avatar_url        = "https://${aws_cloudfront_distribution.ugc.domain_name}/avatars/user456.jpg"
    website_url       = "https://${aws_cloudfront_distribution.website.domain_name}"
  }
  description = "Example URLs for accessing content"
}
