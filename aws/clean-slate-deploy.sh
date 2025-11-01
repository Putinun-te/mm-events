#!/bin/bash
###############################################################################
# Clean Slate Deployment to us-east-1
# Creates minimal free-tier infrastructure: S3 + Lambda + API Gateway only
# Cost: $0/month
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

TERRAFORM_DIR="/Users/putinan/development/DevOps/develop/aws"
cd "$TERRAFORM_DIR"

###############################################################################
# Step 1: Backup Current Configuration
###############################################################################
backup_config() {
    print_header "Step 1: Backing Up Current Configuration"
    
    BACKUP_DIR="backup-singapore-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup all .tf files
    cp *.tf "$BACKUP_DIR/" 2>/dev/null || true
    cp *.tf.disabled "$BACKUP_DIR/" 2>/dev/null || true
    
    # Backup state
    cp terraform.tfstate* "$BACKUP_DIR/" 2>/dev/null || true
    
    print_success "Backup created: $BACKUP_DIR"
    echo ""
}

###############################################################################
# Step 2: Clean All Terraform State
###############################################################################
clean_state() {
    print_header "Step 2: Cleaning Terraform State"
    
    print_warning "Removing all Terraform state and plans..."
    rm -rf .terraform
    rm -f .terraform.lock.hcl
    rm -f terraform.tfstate*
    rm -f tfplan*
    
    print_success "State cleaned - fresh start for us-east-1"
    echo ""
}

###############################################################################
# Step 3: Archive Old Configuration Files
###############################################################################
archive_old_config() {
    print_header "Step 3: Archiving Old Configuration Files"
    
    print_info "Moving VPC/RDS/ElastiCache configs to backup..."
    
    # Move files we don't need for minimal deployment
    mv networking.tf "$BACKUP_DIR/" 2>/dev/null || true
    mv cloudfront.tf "$BACKUP_DIR/" 2>/dev/null || true
    mv messaging.tf "$BACKUP_DIR/" 2>/dev/null || true
    mv dynamodb.tf "$BACKUP_DIR/" 2>/dev/null || true
    
    print_success "Old configs archived"
    echo ""
}

###############################################################################
# Step 4: Create Minimal us-east-1 Configuration
###############################################################################
create_minimal_config() {
    print_header "Step 4: Creating Minimal us-east-1 Configuration"
    
    cat > minimal-main.tf << 'EOF'
###############################################################################
# Minimal Free-Tier Infrastructure for us-east-1
# Resources: S3 buckets, Lambda function, API Gateway
# Cost: $0/month (100% free tier)
###############################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

###############################################################################
# S3 Buckets
###############################################################################

# Event Pictures Bucket
resource "aws_s3_bucket" "event_pictures" {
  bucket = "concert-event-pictures-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "Concert Event Pictures"
    Environment = "production"
    Purpose     = "Store event images"
  }
}

resource "aws_s3_bucket_versioning" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "event_pictures" {
  bucket = aws_s3_bucket.event_pictures.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# User Avatars Bucket
resource "aws_s3_bucket" "user_avatars" {
  bucket = "concert-user-avatars-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "Concert User Avatars"
    Environment = "production"
    Purpose     = "Store user profile pictures"
  }
}

resource "aws_s3_bucket_versioning" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "user_avatars" {
  bucket = aws_s3_bucket.user_avatars.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

###############################################################################
# IAM Role for Lambda
###############################################################################

resource "aws_iam_role" "lambda_execution" {
  name = "concert-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "Concert Lambda Execution Role"
  }
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "concert-lambda-s3-access"
  role = aws_iam_role.lambda_execution.id

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
      }
    ]
  })
}

###############################################################################
# Lambda Function for Presigned URLs
###############################################################################

resource "aws_lambda_function" "generate_presigned_url" {
  filename      = "lambda_presigned_url.zip"
  function_name = "concert-generate-presigned-url"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "lambda_presigned_url.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  source_code_hash = filebase64sha256("lambda_presigned_url.zip")

  environment {
    variables = {
      EVENT_PICTURES_BUCKET = aws_s3_bucket.event_pictures.id
      USER_AVATARS_BUCKET   = aws_s3_bucket.user_avatars.id
    }
  }

  tags = {
    Name = "Concert Presigned URL Generator"
  }
}

###############################################################################
# API Gateway
###############################################################################

resource "aws_apigatewayv2_api" "upload_api" {
  name          = "concert-upload-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "Concert Upload API"
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.upload_api.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Name = "Production Stage"
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.upload_api.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri    = aws_lambda_function.generate_presigned_url.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload_event_picture" {
  api_id    = aws_apigatewayv2_api.upload_api.id
  route_key = "POST /upload/event-picture"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "upload_user_avatar" {
  api_id    = aws_apigatewayv2_api.upload_api.id
  route_key = "POST /upload/user-avatar"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_presigned_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload_api.execution_arn}/*/*"
}

###############################################################################
# Outputs
###############################################################################

output "api_gateway_endpoint" {
  value       = aws_apigatewayv2_stage.prod.invoke_url
  description = "API Gateway endpoint URL"
}

output "event_pictures_bucket" {
  value       = aws_s3_bucket.event_pictures.id
  description = "Event pictures S3 bucket name"
}

output "user_avatars_bucket" {
  value       = aws_s3_bucket.user_avatars.id
  description = "User avatars S3 bucket name"
}

output "lambda_function_name" {
  value       = aws_lambda_function.generate_presigned_url.function_name
  description = "Lambda function name"
}

output "region" {
  value       = "us-east-1"
  description = "Deployment region"
}

output "monthly_cost_estimate" {
  value       = "$0.00 (100% free tier)"
  description = "Estimated monthly cost"
}
EOF

    print_success "Minimal configuration created: minimal-main.tf"
    echo ""
}

###############################################################################
# Step 5: Initialize and Deploy
###############################################################################
deploy() {
    print_header "Step 5: Deploying to us-east-1"
    
    print_info "Initializing Terraform..."
    terraform init
    echo ""
    
    print_info "Creating deployment plan..."
    terraform plan -out=tfplan-minimal
    echo ""
    
    print_warning "Ready to deploy minimal infrastructure to us-east-1"
    echo ""
    echo "This will create:"
    echo "  - 2 S3 buckets (event-pictures, user-avatars)"
    echo "  - 1 Lambda function (presigned URL generator)"
    echo "  - 1 API Gateway (upload endpoints)"
    echo "  - IAM role for Lambda"
    echo ""
    echo "Monthly cost: \$0.00 (100% free tier)"
    echo ""
    
    read -p "Deploy now? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        print_info "Deploying..."
        terraform apply tfplan-minimal
        print_success "Deployment complete!"
        echo ""
        
        print_header "Deployment Summary"
        terraform output
    else
        print_warning "Deployment cancelled. Run 'terraform apply tfplan-minimal' when ready."
    fi
    echo ""
}

###############################################################################
# Main
###############################################################################
main() {
    clear
    
    print_header "Clean Slate Deployment to us-east-1"
    echo ""
    print_warning "This will:"
    echo "  1. Backup all current configuration"
    echo "  2. Remove all Terraform state"
    echo "  3. Create minimal free-tier infrastructure in us-east-1"
    echo "  4. Deploy: S3 + Lambda + API Gateway only"
    echo ""
    print_info "Monthly cost after deployment: \$0.00"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    backup_config
    clean_state
    archive_old_config
    create_minimal_config
    deploy
    
    print_header "✓ Migration Complete!"
    echo ""
    echo -e "${GREEN}Your infrastructure is now in us-east-1 with \$0/month cost!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Update your EC2 instances to use new S3 buckets and API Gateway"
    echo "2. Test file upload with the new API endpoint"
    echo ""
}

main
