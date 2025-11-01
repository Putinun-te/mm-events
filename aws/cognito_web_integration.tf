# ============================================================================
# COGNITO WEB INTEGRATION FOR FRONTEND
# ============================================================================
# Purpose: Integrate Cognito authentication with S3-hosted website
# Features:
#   - Hosted UI for login/signup
#   - Social identity providers (Google, Facebook - optional)
#   - OAuth 2.0 / OIDC flows
#   - Custom domain support
# ============================================================================

# ============================================================================
# COGNITO USER POOL DOMAIN (for Hosted UI)
# ============================================================================
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-auth-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ============================================================================
# COGNITO IDENTITY POOL (for AWS resource access)
# ============================================================================
# Allows authenticated users to access AWS resources (S3, etc.)
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.project_name}-identity-pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  tags = {
    Name        = "${var.project_name}-identity-pool"
    Environment = var.environment
  }
}

# ============================================================================
# IAM ROLES FOR COGNITO IDENTITY POOL
# ============================================================================

# Authenticated users role
resource "aws_iam_role" "cognito_authenticated" {
  name = "${var.project_name}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cognito-authenticated"
    Environment = var.environment
  }
}

# Policy for authenticated users to upload to S3
resource "aws_iam_role_policy" "cognito_authenticated_policy" {
  name = "${var.project_name}-cognito-authenticated-policy"
  role = aws_iam_role.cognito_authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.user_avatars.arn}/users/$${cognito-identity.amazonaws.com:sub}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.user_avatars.arn
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = ["users/$${cognito-identity.amazonaws.com:sub}/*"]
          }
        }
      }
    ]
  })
}

# Attach identity pool roles
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    authenticated = aws_iam_role.cognito_authenticated.arn
  }
}

# ============================================================================
# UPDATE USER POOL CLIENT FOR WEB INTEGRATION
# ============================================================================
# Enhanced client configuration for web application
resource "aws_cognito_user_pool_client" "web_app" {
  name         = "${var.project_name}-web-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth settings
  generate_secret                      = false # For SPA (public client)
  refresh_token_validity               = 30
  access_token_validity                = 60
  id_token_validity                    = 60
  token_validity_units {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  # OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]

  # Callback URLs (localhost for development)
  # Note: S3 website URLs use HTTP, which Cognito doesn't allow
  # For production, use CloudFront with HTTPS or custom domain with SSL
  callback_urls = [
    "http://localhost:3000/auth/callback",
    "http://localhost:3000"
  ]

  logout_urls = [
    "http://localhost:3000"
  ]

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]
  # Add when configured: ["COGNITO", "Google", "Facebook"]

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read/Write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "picture",
    "preferred_username"
  ]

  write_attributes = [
    "email",
    "name",
    "picture",
    "preferred_username"
  ]
}

# ============================================================================
# OUTPUTS FOR FRONTEND CONFIGURATION
# ============================================================================
output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.main.id
  description = "Cognito User Pool ID for frontend config"
}

output "cognito_web_client_id" {
  value       = aws_cognito_user_pool_client.web_app.id
  description = "Cognito Web App Client ID for frontend config"
}

output "cognito_identity_pool_id" {
  value       = aws_cognito_identity_pool.main.id
  description = "Cognito Identity Pool ID for AWS SDK"
}

output "cognito_hosted_ui_url" {
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
  description = "Cognito Hosted UI URL"
}

output "cognito_login_url" {
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.web_app.id}&response_type=code&redirect_uri=http://${aws_s3_bucket.dev_frontend.bucket}.s3-website-${var.aws_region}.amazonaws.com/auth/callback"
  description = "Direct Cognito login URL"
}

output "frontend_cognito_config" {
  value = jsonencode({
    region         = var.aws_region
    userPoolId     = aws_cognito_user_pool.main.id
    userPoolWebClientId = aws_cognito_user_pool_client.web_app.id
    identityPoolId = aws_cognito_identity_pool.main.id
    oauth = {
      domain       = "${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
      scope        = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
      redirectSignIn  = "http://${aws_s3_bucket.dev_frontend.bucket}.s3-website-${var.aws_region}.amazonaws.com/auth/callback"
      redirectSignOut = "http://${aws_s3_bucket.dev_frontend.bucket}.s3-website-${var.aws_region}.amazonaws.com"
      responseType = "code"
    }
  })
  description = "Complete Cognito configuration for frontend (copy to nuxt.config.ts)"
  sensitive   = false
}
