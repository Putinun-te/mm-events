resource "aws_cognito_user_pool" "this" {
  name = "${var.name}-user-pool"

  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"
  deletion_protection      = "ACTIVE"

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-user-pool"
  })
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.name}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  allowed_oauth_flows_user_pool_client = false
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  generate_secret               = false

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "this" {
  count        = var.domain_prefix == "" ? 0 : 1
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}
