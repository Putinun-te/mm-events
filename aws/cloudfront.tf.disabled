# ============================================================================
# CLOUDFRONT CDN FOR WEB HOSTING
# ============================================================================
# Purpose: Host frontend web application and serve S3 content globally
# Benefits:
#   - FREE TIER: 1 TB/month data transfer OUT
#   - 10M HTTP/HTTPS requests/month FREE
#   - Free SSL certificates via ACM
#   - Low latency global content delivery
#   - Reduces S3 costs by caching content
# ============================================================================

# ============================================================================
# ORIGIN ACCESS CONTROL (OAC) - Modern replacement for OAI
# ============================================================================
# OAC is the recommended way to give CloudFront access to S3 buckets
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-s3-oac"
  description                       = "Origin Access Control for Concert S3 buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ============================================================================
# CLOUDFRONT CACHE POLICIES
# ============================================================================
# Custom cache policy for static assets (images, CSS, JS)
resource "aws_cloudfront_cache_policy" "static_assets" {
  name        = "${var.project_name}-static-assets-cache"
  comment     = "Cache policy for static assets with long TTL"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
      }
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Custom cache policy for dynamic content (HTML files)
resource "aws_cloudfront_cache_policy" "dynamic_content" {
  name        = "${var.project_name}-dynamic-content-cache"
  comment     = "Cache policy for HTML with shorter TTL"
  default_ttl = 300  # 5 minutes
  max_ttl     = 3600 # 1 hour
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
      }
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# ============================================================================
# CLOUDFRONT DISTRIBUTION FOR WEB HOSTING
# ============================================================================
resource "aws_cloudfront_distribution" "web_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Concert Platform - Web Application CDN"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # North America & Europe (cheaper)

  # ============================================================================
  # ORIGIN 1: Frontend Web Application (S3)
  # ============================================================================
  origin {
    domain_name              = aws_s3_bucket.dev_frontend.bucket_regional_domain_name
    origin_id                = "S3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id

    custom_header {
      name  = "X-Origin-Verify"
      value = "concert-platform-${var.environment}"
    }
  }

  # ============================================================================
  # ORIGIN 2: Event Pictures (S3)
  # ============================================================================
  origin {
    domain_name              = aws_s3_bucket.event_pictures.bucket_regional_domain_name
    origin_id                = "S3-event-pictures"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id

    custom_header {
      name  = "X-Origin-Verify"
      value = "concert-platform-${var.environment}"
    }
  }

  # ============================================================================
  # ORIGIN 3: User Avatars (S3)
  # ============================================================================
  origin {
    domain_name              = aws_s3_bucket.user_avatars.bucket_regional_domain_name
    origin_id                = "S3-user-avatars"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id

    custom_header {
      name  = "X-Origin-Verify"
      value = "concert-platform-${var.environment}"
    }
  }

  # ============================================================================
  # ORIGIN 4: Backend API (Optional - uncomment when ALB is configured)
  # ============================================================================
  # Uncomment this when you have an Application Load Balancer for the backend
  # origin {
  #   domain_name = aws_lb.backend_alb.dns_name  # or your ALB DNS
  #   origin_id   = "backend-api"
  #
  #   custom_origin_config {
  #     http_port              = 80
  #     https_port             = 443
  #     origin_protocol_policy = "http-only"
  #     origin_ssl_protocols   = ["TLSv1.2"]
  #   }
  #
  #   custom_header {
  #     name  = "X-Origin-Verify"
  #     value = "concert-platform-${var.environment}"
  #   }
  # }

  # ============================================================================
  # DEFAULT CACHE BEHAVIOR (Frontend Web Application)
  # ============================================================================
  default_cache_behavior {
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https" # Force HTTPS
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.dynamic_content.id

    # SPA support: Return index.html for 403/404 errors
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_router.arn
    }
  }

  # ============================================================================
  # CACHE BEHAVIOR: API Requests (/api/*) - Uncomment when backend origin is added
  # ============================================================================
  # ordered_cache_behavior {
  #   path_pattern           = "/api/*"
  #   target_origin_id       = "backend-api"
  #   viewer_protocol_policy = "redirect-to-https"
  #   allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  #   cached_methods         = ["GET", "HEAD"]
  #   compress               = true
  #
  #   # Don't cache API responses
  #   min_ttl     = 0
  #   default_ttl = 0
  #   max_ttl     = 0
  #
  #   forwarded_values {
  #     query_string = true
  #     headers      = ["Authorization", "Origin", "Accept", "Content-Type"]
  #
  #     cookies {
  #       forward = "all"
  #     }
  #   }
  # }

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

    cache_policy_id = aws_cloudfront_cache_policy.static_assets.id
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

    cache_policy_id = aws_cloudfront_cache_policy.static_assets.id
  }

  # ============================================================================
  # CACHE BEHAVIOR: Static Assets (CSS, JS, Images)
  # ============================================================================
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.static_assets.id
  }

  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.static_assets.id
  }

  ordered_cache_behavior {
    path_pattern           = "*.css"
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.static_assets.id
  }

  ordered_cache_behavior {
    path_pattern           = "*.js"
    target_origin_id       = "S3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = aws_cloudfront_cache_policy.static_assets.id
  }

  # ============================================================================
  # GEO RESTRICTIONS
  # ============================================================================
  restrictions {
    geo_restriction {
      restriction_type = "none"
      # Optional: Restrict to specific countries to reduce costs
      # restriction_type = "whitelist"
      # locations        = ["US", "CA", "GB", "DE", "TH", "SG", "JP"]
    }
  }

  # ============================================================================
  # SSL/TLS CERTIFICATE
  # ============================================================================
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"

    # For custom domain (uncomment when ready):
    # acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    # ssl_support_method       = "sni-only"  # FREE (dedicated IP = $600/month)
    # minimum_protocol_version = "TLSv1.2_2021"
  }

  # ============================================================================
  # CUSTOM ERROR RESPONSES (SPA Support)
  # ============================================================================
  # Return index.html for 404 errors (SPA routing)
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # Return index.html for 403 errors (SPA routing)
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # ============================================================================
  # LOGGING (Optional - costs extra storage)
  # ============================================================================
  # logging_config {
  #   include_cookies = false
  #   bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
  #   prefix          = "cloudfront-logs/"
  # }

  tags = {
    Name        = "${var.project_name}-web-distribution"
    Environment = var.environment
    Purpose     = "Web hosting and global CDN"
    FreeTier    = "true"
  }
}

# ============================================================================
# CLOUDFRONT FUNCTION - SPA Router
# ============================================================================
# Handles client-side routing for single-page applications
resource "aws_cloudfront_function" "spa_router" {
  name    = "${var.project_name}-spa-router"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite requests to index.html for SPA routing"
  publish = true

  code = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Check if URI is missing file extension (SPA route)
    if (!uri.includes('.')) {
        request.uri = '/index.html';
    }
    
    return request;
}
EOT
}

# ============================================================================
# UPDATE S3 BUCKET POLICIES - Allow CloudFront OAC Access
# ============================================================================

# Frontend bucket policy
resource "aws_s3_bucket_policy" "frontend_cloudfront" {
  bucket = aws_s3_bucket.dev_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.dev_frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.web_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.dev_frontend]
}

# Event pictures bucket policy
resource "aws_s3_bucket_policy" "event_pictures_cloudfront" {
  bucket = aws_s3_bucket.event_pictures.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.event_pictures.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.web_distribution.arn
          }
        }
      },
      {
        Sid    = "AllowBackendEC2Write"
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

  depends_on = [aws_s3_bucket_public_access_block.event_pictures]
}

# User avatars bucket policy
resource "aws_s3_bucket_policy" "user_avatars_cloudfront" {
  bucket = aws_s3_bucket.user_avatars.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.user_avatars.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.web_distribution.arn
          }
        }
      },
      {
        Sid    = "AllowBackendEC2Write"
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

  depends_on = [aws_s3_bucket_public_access_block.user_avatars]
}

# ============================================================================
# CLOUDFRONT MONITORING & ALARMS
# ============================================================================

# CloudWatch Alarm: Monitor data transfer (stay within 1 TB free tier)
resource "aws_cloudwatch_metric_alarm" "cloudfront_data_transfer" {
  alarm_name          = "${var.project_name}-cloudfront-data-transfer"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BytesDownloaded"
  namespace           = "AWS/CloudFront"
  period              = 86400 # 1 day
  statistic           = "Sum"
  threshold           = 900000000000 # 900 GB (90% of 1 TB)
  alarm_description   = "Alert when CloudFront data transfer exceeds 900 GB/day"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.web_distribution.id
  }

  tags = {
    Name        = "CloudFront Data Transfer Monitor"
    Environment = var.environment
  }
}

# CloudWatch Alarm: Monitor request count (stay within 10M free tier)
resource "aws_cloudwatch_metric_alarm" "cloudfront_requests" {
  alarm_name          = "${var.project_name}-cloudfront-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Requests"
  namespace           = "AWS/CloudFront"
  period              = 86400 # 1 day
  statistic           = "Sum"
  threshold           = 300000 # 300k/day (~90% of 10M/month)
  alarm_description   = "Alert when CloudFront requests exceed 300k/day"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.web_distribution.id
  }

  tags = {
    Name        = "CloudFront Request Count Monitor"
    Environment = var.environment
  }
}

# CloudWatch Alarm: Monitor 4xx error rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "${var.project_name}-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 5 # 5% error rate
  alarm_description   = "Alert when 4xx error rate exceeds 5%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.web_distribution.id
  }

  tags = {
    Name        = "CloudFront 4xx Error Monitor"
    Environment = var.environment
  }
}

# CloudWatch Alarm: Monitor 5xx error rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  alarm_name          = "${var.project_name}-cloudfront-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 1 # 1% error rate
  alarm_description   = "Alert when 5xx error rate exceeds 1%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.web_distribution.id
  }

  tags = {
    Name        = "CloudFront 5xx Error Monitor"
    Environment = var.environment
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================
output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.web_distribution.id
  description = "CloudFront distribution ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.web_distribution.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.web_distribution.domain_name}"
  description = "Full CloudFront HTTPS URL for web application"
}

output "cloudfront_event_pictures_url" {
  value       = "https://${aws_cloudfront_distribution.web_distribution.domain_name}/events/"
  description = "CloudFront URL for event pictures"
}

output "cloudfront_avatars_url" {
  value       = "https://${aws_cloudfront_distribution.web_distribution.domain_name}/avatars/"
  description = "CloudFront URL for user avatars"
}

output "cloudfront_api_url" {
  value       = "https://${aws_cloudfront_distribution.web_distribution.domain_name}/api"
  description = "CloudFront URL for backend API (proxied)"
}
