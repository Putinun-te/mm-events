data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-lambda-role"
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name}:*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ]
          Resource = "*"
        }
      ],
      var.efs_file_system_arn != "" ? [{
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeMountTargets"
        ]
        Resource = [
          var.efs_file_system_arn,
          var.efs_access_point_arn
        ]
      }] : [],
      var.secret_arn != "" ? [{
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secret_arn
      }] : [],
      var.s3_bucket_arn != "" ? [{
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }] : [],
      var.elasticache_cache_arn != "" ? [{
        Effect = "Allow"
        Action = [
          "elasticache:Connect"
        ]
        Resource = [var.elasticache_cache_arn]
      }] : []
    )
  })
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.lambda.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.cloudwatch_kms_key_id == "" ? null : var.cloudwatch_kms_key_id

  tags = merge(var.tags, {
    Name = "${var.name}-logs"
  })
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.lambda.arn
  package_type  = var.package_type
  image_uri     = var.package_type == "Image" ? var.image_uri : null
  filename      = var.package_type == "Zip" ? var.deployment_package_path : null
  handler       = var.package_type == "Zip" ? var.handler : null
  runtime       = var.package_type == "Zip" ? var.runtime : null
  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = [var.architecture]

  dynamic "environment" {
    for_each = length(var.environment_variables) == 0 ? [] : [1]
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) == 0 ? [] : [1]
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "file_system_config" {
    for_each = var.efs_access_point_arn == "" ? [] : [1]
    content {
      arn              = var.efs_access_point_arn
      local_mount_path = var.efs_mount_path
    }
  }

  source_code_hash = var.package_type == "Zip" && var.deployment_package_path != null ? filebase64sha256(var.deployment_package_path) : null

  depends_on = [aws_cloudwatch_log_group.lambda]

  lifecycle {
    ignore_changes = [environment, image_uri]
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.name}-api"
  protocol_type = "HTTP"

  tags = merge(var.tags, {
    Name = "${var.name}-api"
  })
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.this.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.enable_jwt_authorizer ? 1 : 0

  api_id = aws_apigatewayv2_api.http.id
  name   = "${var.name}-jwt"
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = var.authorizer_audience
    issuer   = var.authorizer_jwt_issuer
  }
}

resource "aws_apigatewayv2_route" "root_proxy" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  # Disable API Gateway JWT auth - let the application handle authentication
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorizer_id      = null
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_execution.arn
    format = jsonencode({
      requestId  = "$context.requestId",
      httpMethod = "$context.httpMethod",
      routeKey   = "$context.routeKey",
      status     = "$context.status",
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}

resource "aws_cloudwatch_log_group" "api_execution" {
  name              = "${var.name}-api-execution"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.cloudwatch_kms_key_id == "" ? null : var.cloudwatch_kms_key_id

  tags = merge(var.tags, {
    Name = "${var.name}-api-logs"
  })
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*"
}
