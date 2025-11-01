#!/bin/bash
###############################################################################
# Complete Infrastructure Deployment Script
# Creates all remaining Terraform files and deploys infrastructure
###############################################################################

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Concert Platform - Full Infrastructure Deployment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Create EC2 configuration
cat > ec2.tf << 'EOF'
###############################################################################
# EC2 Auto Scaling Group
###############################################################################

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role-${var.environment}"

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
    Name = "${var.project_name}-ec2-role"
  }
}

# IAM Policy for EC2
resource "aws_iam_role_policy" "ec2" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.event_pictures.arn,
          "${aws_s3_bucket.event_pictures.arn}/*",
          aws_s3_bucket.user_avatars.arn,
          "${aws_s3_bucket.user_avatars.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Update system
              dnf update -y
              
              # Install Docker
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # Install Java 17
              dnf install -y java-17-amazon-corretto-headless
              
              # Install CloudWatch agent
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
              rpm -U ./amazon-cloudwatch-agent.rpm
              
              # Create application directory
              mkdir -p /opt/concert
              chown ec2-user:ec2-user /opt/concert
              
              # Install application (placeholder - update with actual deployment)
              echo "Application will be deployed here" > /opt/concert/README.txt
              
              EOF
  )

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-asg-${var.environment}"
  vpc_zone_identifier = aws_subnet.public[*].id # Use public subnets
  
  min_size         = var.ec2_min_size
  max_size         = var.ec2_max_size
  desired_capacity = var.ec2_desired_capacity

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policy - Scale Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch Alarm - High CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

# Auto Scaling Policy - Scale Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch Alarm - Low CPU
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}
EOF

echo -e "${GREEN}✓ Created ec2.tf${NC}"

# Create Lambda and API Gateway configuration
cat > lambda.tf << 'EOF'
###############################################################################
# Lambda Functions and API Gateway
###############################################################################

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role-${var.environment}"

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

  tags = {
    Name = "${var.project_name}-lambda-role"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.event_pictures.arn}/*",
          "${aws_s3_bucket.user_avatars.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
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
    ]
  })
}

# Lambda function for presigned URLs
resource "aws_lambda_function" "presigned_url" {
  filename      = "lambda_presigned_url.zip"
  function_name = "${var.project_name}-presigned-url-${var.environment}"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_presigned_url.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  source_code_hash = fileexists("lambda_presigned_url.zip") ? filebase64sha256("lambda_presigned_url.zip") : null

  environment {
    variables = {
      EVENT_PICTURES_BUCKET = aws_s3_bucket.event_pictures.id
      USER_AVATARS_BUCKET   = aws_s3_bucket.user_avatars.id
    }
  }

  tags = {
    Name = "${var.project_name}-presigned-url-function"
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  tags = {
    Name = "${var.project_name}-api-stage"
  }
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri    = aws_lambda_function.presigned_url.invoke_arn
  payload_format_version = "2.0"
}

# API Gateway Routes
resource "aws_apigatewayv2_route" "upload_event" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /upload/event-picture"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "upload_avatar" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /upload/user-avatar"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
EOF

echo -e "${GREEN}✓ Created lambda.tf${NC}"

# Create outputs file
cat > outputs.tf << 'EOF'
###############################################################################
# Outputs
###############################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "db_secret_arn" {
  description = "ARN of database credentials secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "s3_event_pictures_bucket" {
  description = "S3 bucket for event pictures"
  value       = aws_s3_bucket.event_pictures.id
}

output "s3_user_avatars_bucket" {
  description = "S3 bucket for user avatars"
  value       = aws_s3_bucket.user_avatars.id
}

output "s3_static_website_bucket" {
  description = "S3 bucket for static website"
  value       = aws_s3_bucket.static_website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_url" {
  description = "CloudFront URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.main.id
}

output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = "${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.main.invoke_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.presigned_url.function_name
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.main.name
}

output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT
    
    ✅ Deployment Complete!
    
    Region: ${var.aws_region}
    Environment: ${var.environment}
    
    🌐 CloudFront CDN:
       https://${aws_cloudfront_distribution.main.domain_name}
    
    🔐 Cognito Auth:
       User Pool ID: ${aws_cognito_user_pool.main.id}
       App Client ID: ${aws_cognito_user_pool_client.web.id}
       Hosted UI: https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com
    
    🗄️  Database:
       Endpoint: ${aws_db_instance.main.endpoint}
       Database: ${aws_db_instance.main.db_name}
       Credentials: (stored in Secrets Manager)
    
    📦 S3 Buckets:
       Event Pictures: ${aws_s3_bucket.event_pictures.id}
       User Avatars: ${aws_s3_bucket.user_avatars.id}
       Static Website: ${aws_s3_bucket.static_website.id}
    
    🔧 API Gateway:
       ${aws_apigatewayv2_stage.main.invoke_url}
    
    🚀 Auto Scaling:
       Min: ${var.ec2_min_size} | Max: ${var.ec2_max_size}
       Current: ${var.ec2_desired_capacity} instance(s)
    
    💰 Estimated Cost: $20/month
    📊 Free Credits Runtime: ~9 months
  EOT
}
EOF

echo -e "${GREEN}✓ Created outputs.tf${NC}"

# Create Lambda deployment package if it doesn't exist
if [ ! -f "lambda_presigned_url.zip" ]; then
  echo -e "${YELLOW}ℹ Creating Lambda deployment package...${NC}"
  cat > lambda_presigned_url.py << 'PYTHON'
import json
import boto3
import os
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        filename = body.get('filename')
        content_type = body.get('contentType', 'image/jpeg')
        
        # Determine bucket based on path
        path = event.get('path', '')
        if 'event-picture' in path:
            bucket = os.environ['EVENT_PICTURES_BUCKET']
        elif 'user-avatar' in path:
            bucket = os.environ['USER_AVATARS_BUCKET']
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid upload type'})
            }
        
        # Generate presigned URL
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket,
                'Key': filename,
                'ContentType': content_type
            },
            ExpiresIn=300  # 5 minutes
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'uploadUrl': presigned_url,
                'key': filename
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
PYTHON

  zip lambda_presigned_url.zip lambda_presigned_url.py
  echo -e "${GREEN}✓ Created Lambda deployment package${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Ready to Deploy!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Run these commands to deploy:"
echo ""
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""
echo -e "${YELLOW}Estimated deployment time: 15-20 minutes${NC}"
echo -e "${YELLOW}Estimated monthly cost: \$20-25${NC}"
echo -e "${YELLOW}Runtime with \$180 credits: 7-9 months${NC}"
echo ""
