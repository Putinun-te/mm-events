# IAM Role for Backend EC2 (for S3 and API Gateway access)
resource "aws_iam_role" "backend_ec2_role" {
  name = "${var.project_name}-backend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Concert Backend EC2 Role"
    Environment = var.environment
  }
}

# Inline policy for S3 access
resource "aws_iam_role_policy" "backend_s3_policy" {
  name   = "${var.project_name}-backend-s3-policy"
  role   = aws_iam_role.backend_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.event_pictures.arn,
          aws_s3_bucket.user_avatars.arn
        ]
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${aws_s3_bucket.event_pictures.arn}/*",
          "${aws_s3_bucket.user_avatars.arn}/*"
        ]
      }
    ]
  })
}

# Instance profile for backend EC2
resource "aws_iam_instance_profile" "backend_ec2_profile" {
  name = "${var.project_name}-backend-ec2-profile"
  role = aws_iam_role.backend_ec2_role.name
}

# IAM Group for Developers
resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

# IAM Policy for Developer S3 Access
resource "aws_iam_group_policy" "developer_s3_policy" {
  name   = "${var.project_name}-developer-s3-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3FullAccess"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.event_pictures.arn,
          "${aws_s3_bucket.event_pictures.arn}/*",
          aws_s3_bucket.user_avatars.arn,
          "${aws_s3_bucket.user_avatars.arn}/*"
        ]
      },
      {
        Sid    = "S3ListAllBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Developer API Gateway Access
resource "aws_iam_group_policy" "developer_apigateway_policy" {
  name   = "${var.project_name}-developer-apigateway-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "APIGatewayManagement"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:DELETE",
          "apigateway:PATCH"
        ]
        Resource = "arn:aws:apigateway:${var.aws_region}::/restapis/*"
      },
      {
        Sid    = "APIGatewayDeploy"
        Effect = "Allow"
        Action = [
          "apigateway:CreateDeployment",
          "apigateway:CreateStage",
          "apigateway:UpdateStage"
        ]
        Resource = "arn:aws:apigateway:${var.aws_region}::/restapis/*"
      }
    ]
  })
}

# IAM Policy for Developer Lambda Access
resource "aws_iam_group_policy" "developer_lambda_policy" {
  name   = "${var.project_name}-developer-lambda-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaFullAccess"
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      },
      {
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
      }
    ]
  })
}

# IAM Policy for Developer CloudFront Access
resource "aws_iam_group_policy" "developer_cloudfront_policy" {
  name   = "${var.project_name}-developer-cloudfront-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontManagement"
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudfront:UpdateDistribution",
          "cloudfront:CreateInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Developer CloudWatch Logs Access
resource "aws_iam_group_policy" "developer_logs_policy" {
  name   = "${var.project_name}-developer-logs-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/concert/*"
      }
    ]
  })
}

# IAM User for Developer (to be created manually via AWS Console with MFA)
# This is a placeholder showing the permissions structure
resource "aws_iam_user" "developer_template" {
  name = "${var.project_name}-developer-template"

  tags = {
    Name        = "Concert Developer Template"
    Environment = var.environment
    Note        = "Use this as template for manual developer user creation in AWS Console"
  }
}

# Add developer user to developers group
resource "aws_iam_user_group_membership" "developer_template" {
  user = aws_iam_user.developer_template.name

  groups = [
    aws_iam_group.developers.name
  ]
}

# Output the developer group name
output "developer_group_name" {
  value       = aws_iam_group.developers.name
  description = "IAM group name for developers - add users to this group"
}

output "backend_ec2_role_arn" {
  value       = aws_iam_role.backend_ec2_role.arn
  description = "ARN of the backend EC2 IAM role"
}

output "backend_ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.backend_ec2_profile.name
  description = "Name of the EC2 instance profile for backend"
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
