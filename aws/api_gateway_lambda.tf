# API Gateway for File Upload
resource "aws_apigatewayv2_api" "file_upload" {
  name          = "${var.project_name}-file-upload-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "https://${var.frontend_domain}",
      "http://localhost:3000"
    ]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    expose_headers = ["content-length", "content-type", "x-amz-version-id"]
    max_age = 300
  }

  tags = {
    Name        = "Concert File Upload API"
    Environment = var.environment
  }
}

# Stage for API Gateway
resource "aws_apigatewayv2_stage" "file_upload" {
  api_id      = aws_apigatewayv2_api.file_upload.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
    })
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-file-upload"
  retention_in_days = 7

  tags = {
    Name        = "Concert File Upload API Logs"
    Environment = var.environment
  }
}

# Lambda Execution Role for GeneratePresignedUrl
resource "aws_iam_role" "lambda_presigned_url_role" {
  name = "${var.project_name}-lambda-presigned-url-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for Lambda to write logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_presigned_url_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for Lambda to access S3
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name   = "${var.project_name}-lambda-s3-policy"
  role   = aws_iam_role.lambda_presigned_url_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3GeneratePresignedUrl"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.event_pictures.arn}/*",
          "${aws_s3_bucket.user_avatars.arn}/*"
        ]
      }
    ]
  })
}

# Lambda Function: GeneratePresignedUrl
resource "aws_lambda_function" "generate_presigned_url" {
  filename      = "lambda_presigned_url.zip"
  function_name = "${var.project_name}-generate-presigned-url"
  role          = aws_iam_role.lambda_presigned_url_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"

  environment {
    variables = {
      EVENT_PICTURES_BUCKET = aws_s3_bucket.event_pictures.id
      USER_AVATARS_BUCKET   = aws_s3_bucket.user_avatars.id
      PRESIGNED_URL_EXPIRATION = "3600"
    }
  }

  tags = {
    Name        = "Concert Generate Presigned URL"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.generate_presigned_url.function_name}"
  retention_in_days = 7
}

# API Gateway Integration with Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.file_upload.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  payload_format_version = "2.0"
  target = aws_lambda_function.generate_presigned_url.arn
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.file_upload.execution_arn}/*/*"
}

# Route: POST /upload/event-picture
resource "aws_apigatewayv2_route" "post_event_picture" {
  api_id    = aws_apigatewayv2_api.file_upload.id
  route_key = "POST /upload/event-picture"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route: POST /upload/avatar
resource "aws_apigatewayv2_route" "post_avatar" {
  api_id    = aws_apigatewayv2_api.file_upload.id
  route_key = "POST /upload/avatar"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Output API Gateway details
output "api_gateway_endpoint" {
  value       = aws_apigatewayv2_api.file_upload.api_endpoint
  description = "API Gateway endpoint URL"
}

output "api_gateway_id" {
  value       = aws_apigatewayv2_api.file_upload.id
  description = "API Gateway ID"
}

output "lambda_function_name" {
  value       = aws_lambda_function.generate_presigned_url.function_name
  description = "Lambda function name for presigned URL generation"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.generate_presigned_url.arn
  description = "Lambda function ARN"
}
