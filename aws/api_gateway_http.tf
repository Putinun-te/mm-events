locals {
  backend_base_url = trimsuffix(var.backend_service_url, "/")
}

resource "aws_cloudwatch_log_group" "http_api_access" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-http"
  retention_in_days = 14
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_api" "concert_http" {
  name          = "${var.project_name}-http-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "HTTP API Gateway for the Concert backend"

  cors_configuration {
    allow_credentials = true
    allow_headers     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins     = var.api_allowed_origins
    expose_headers    = ["Authorization", "Content-Type"]
    max_age           = 3600
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_integration" "concert_backend" {
  api_id                 = aws_apigatewayv2_api.concert_http.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "${local.backend_base_url}/api/{proxy}"
  integration_method     = "ANY"
  payload_format_version = "1.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_route" "concert_api_proxy" {
  api_id    = aws_apigatewayv2_api.concert_http.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.concert_backend.id}"
}

resource "aws_apigatewayv2_integration" "concert_backend_root" {
  api_id                 = aws_apigatewayv2_api.concert_http.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "${local.backend_base_url}/api"
  integration_method     = "ANY"
  payload_format_version = "1.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_route" "concert_api_root" {
  api_id    = aws_apigatewayv2_api.concert_http.id
  route_key = "ANY /api"
  target    = "integrations/${aws_apigatewayv2_integration.concert_backend_root.id}"
}

resource "aws_apigatewayv2_stage" "concert_http" {
  api_id      = aws_apigatewayv2_api.concert_http.id
  name        = var.api_stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      ip               = "$context.identity.sourceIp"
      userAgent        = "$context.identity.userAgent"
    })
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
