# ============================================================================
# CLOUDFRONT CDN CONFIGURATION (FREE TIER: 1 TB/month data transfer)
# ============================================================================
# Purpose: Serve S3 content globally with low latency and HTTPS
# Benefits:
#   - 1 TB/month data transfer OUT (vs 100 GB from S3)
#   - 10M HTTP/HTTPS requests/month FREE
#   - Free SSL certificates via ACM
#   - Reduces S3 GET requests (stays within 20k/month limit)
# ============================================================================

# Origin Access Identity - Allows CloudFront to access private S3 buckets
resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  comment = "OAI for Concert S3 buckets - Event Pictures and User Avatars"
}

# ============================================================================
# CLOUDFRONT DISTRIBUTION
# ============================================================================
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Concert Platform CDN - Images and Assets"
  default_root_object = "index.html"
  
  # Price Class 100 = Only North America & Europe (cheaper, still good coverage)
  # Price Class All = All edge locations (more expensive outside free tier)
  price_class = "PriceClass_100"

  # ============================================================================
  # ORIGIN 1: Event Pictures S3 Bucket
  # ============================================================================
  origin {
    domain_name = aws_s3_bucket.event_pictures.bucket_regional_domain_name
    origin_id   = "S3-event-pictures"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
    
    # Custom headers for origin
    custom_header {
      name  = "X-Origin-Verify"
      value = "concert-platform-${var.environment}"
    }
  }

  # ============================================================================
  # ORIGIN 2: User Avatars S3 Bucket
  # ============================================================================
  origin {
    domain_name = aws_s3_bucket.user_avatars.bucket_regional_domain_name
    origin_id   = "S3-user-avatars"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
    
    custom_header {
      name  = "X-Origin-Verify"
      value = "concert-platform-${var.environment}"
    }
  }

  # ============================================================================
  # DEFAULT CACHE BEHAVIOR (Event Pictures)
  # ============================================================================
  default_cache_behavior {
    target_origin_id       = "S3-event-pictures"
    viewer_protocol_policy = "redirect-to-https"  # Force HTTPS
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true  # Enable Gzip/Brotli compression
    
    # Cache settings for optimal free tier usage
    min_ttl     = 0
    default_ttl = 86400      # 1 day (24 hours)
    max_ttl     = 31536000   # 1 year
    
    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
      
      cookies {
        forward = "none"
      }
    }
    
    # Lambda@Edge functions (commented out to stay in free tier)
    # lambda_function_association {
    #   event_type   = "viewer-request"
    #   lambda_arn   = aws_lambda_function.image_optimizer.qualified_arn
    # }
  }

  # ============================================================================
  # CACHE BEHAVIOR: User Avatars (/avatars/*)
  # ============================================================================
  ordered_cache_behavior {
    path_pattern           = "/avatars/*"
    target_origin_id       = "S3-user-avatars"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    min_ttl     = 0
    default_ttl = 86400      # 1 day
    max_ttl     = 31536000   # 1 year
    
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
  }

  # ============================================================================
  # CACHE BEHAVIOR: Event Pictures (/events/*)
  # ============================================================================
  ordered_cache_behavior {
    path_pattern           = "/events/*"
    target_origin_id       = "S3-event-pictures"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
    
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
  }

  # ============================================================================
  # GEO RESTRICTIONS (Optional - can restrict to reduce costs)
  # ============================================================================
  restrictions {
    geo_restriction {
      restriction_type = "none"
      # Optionally restrict to specific countries:
      # restriction_type = "whitelist"
      # locations        = ["US", "CA", "GB", "DE", "TH", "SG", "JP"]
    }
  }

  # ============================================================================
  # SSL/TLS CERTIFICATE
  # ============================================================================
  viewer_certificate {
    # Option 1: Use CloudFront default certificate (FREE, *.cloudfront.net domain)
    cloudfront_default_certificate = true
    
    # Option 2: Use custom SSL certificate from ACM (FREE, but need custom domain)
    # acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    # ssl_support_method       = "sni-only"  # FREE (vs dedicated IP = $600/month)
    # minimum_protocol_version = "TLSv1.2_2021"
  }

  # ============================================================================
  # CUSTOM ERROR RESPONSES
  # ============================================================================
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  # ============================================================================
  # LOGGING (Optional - S3 Standard-IA after 30 days to save cost)
  # ============================================================================
  # logging_config {
  #   include_cookies = false
  #   bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
  #   prefix          = "cloudfront-logs/"
  # }

  tags = {
    Name        = "Concert Platform CDN"
    Environment = var.environment
    Purpose     = "Global content delivery for images and static assets"
    FreeTier    = "true"
  }
}

# ============================================================================
# UPDATE S3 BUCKET POLICIES - Allow CloudFront OAI + Lambda Access
# ============================================================================
# CloudFront can READ, Lambda can WRITE

resource "aws_s3_bucket_policy" "event_pictures_cloudfront" {
  bucket = aws_s3_bucket.event_pictures.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.s3_oai.iam_arn
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
    aws_cloudfront_origin_access_identity.s3_oai,
    aws_s3_bucket_public_access_block.event_pictures
  ]
}

resource "aws_s3_bucket_policy" "user_avatars_cloudfront" {
  bucket = aws_s3_bucket.user_avatars.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.s3_oai.iam_arn
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
    aws_cloudfront_origin_access_identity.s3_oai,
    aws_s3_bucket_public_access_block.user_avatars
  ]
}

# ============================================================================
# OUTPUTS
# ============================================================================
output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.s3_distribution.id
  description = "CloudFront distribution ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "CloudFront distribution domain name (use this in frontend)"
}

output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
  description = "Full CloudFront HTTPS URL"
}

output "cloudfront_event_pictures_url" {
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/events/"
  description = "CloudFront URL for event pictures"
}

output "cloudfront_avatars_url" {
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/avatars/"
  description = "CloudFront URL for user avatars"
}

# ============================================================================
# FREE TIER MONITORING
# ============================================================================
# CloudWatch Alarm: Monitor data transfer to stay within 1 TB/month
resource "aws_cloudwatch_metric_alarm" "cloudfront_data_transfer" {
  alarm_name          = "${var.project_name}-cloudfront-data-transfer-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BytesDownloaded"
  namespace           = "AWS/CloudFront"
  period              = 86400  # 1 day
  statistic           = "Sum"
  threshold           = 900000000000  # 900 GB (90% of 1 TB)
  alarm_description   = "Alert when CloudFront data transfer exceeds 900 GB in a day"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.s3_distribution.id
  }

  tags = {
    Name        = "CloudFront Data Transfer Monitor"
    Environment = var.environment
  }
}

# CloudWatch Alarm: Monitor request count to stay within 10M/month
resource "aws_cloudwatch_metric_alarm" "cloudfront_requests" {
  alarm_name          = "${var.project_name}-cloudfront-requests-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Requests"
  namespace           = "AWS/CloudFront"
  period              = 86400  # 1 day
  statistic           = "Sum"
  threshold           = 300000  # 300k/day (90% of 10M/month ÷ 30 days)
  alarm_description   = "Alert when CloudFront requests exceed 300k in a day"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.s3_distribution.id
  }

  tags = {
    Name        = "CloudFront Request Count Monitor"
    Environment = var.environment
  }
}
