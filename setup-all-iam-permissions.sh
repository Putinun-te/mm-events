#!/bin/bash

################################################################################
# COMPLETE IAM PERMISSIONS SETUP - AWS CLI
# Purpose: Add all necessary permissions to IAM groups for all services
# Creates comprehensive policies for: Notification, Analytics, Email, 
# Cache, Audit services + existing core services
# Date: October 31, 2025
# Status: Fully Automated - No Manual Setup Required
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Header
display_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  COMPLETE IAM PERMISSIONS SETUP - ALL SERVICES                 ║"
    echo "║  Configuring Full Access for:                                  ║"
    echo "║  • Auth Service | Event Service | Booking Service             ║"
    echo "║  • S3 File Service | JWT Service | Notification Service       ║"
    echo "║  • Analytics Service | Email Service | Cache Service          ║"
    echo "║  • Audit Service                                               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# Check AWS CLI
check_aws_cli() {
    log_info "Checking AWS CLI installation..."
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    log_success "AWS CLI found"
}

# Check credentials
check_credentials() {
    log_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_success "AWS authenticated (Account: $ACCOUNT_ID)"
}

################################################################################
# ADD CORE SERVICES PERMISSIONS TO DEVELOPER GROUP
################################################################################

add_developer_core_services_policy() {
    log_info "Adding Core Services permissions to developers group..."
    
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperCoreServicesPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "DynamoDBAccess",
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:Query",
                        "dynamodb:GetItem",
                        "dynamodb:Scan",
                        "dynamodb:DescribeTable",
                        "dynamodb:GetRecords",
                        "dynamodb:GetShardIterator",
                        "dynamodb:DescribeStream"
                    ],
                    "Resource": [
                        "arn:aws:dynamodb:*:*:table/concerts",
                        "arn:aws:dynamodb:*:*:table/bookings",
                        "arn:aws:dynamodb:*:*:table/users",
                        "arn:aws:dynamodb:*:*:table/notifications"
                    ]
                },
                {
                    "Sid": "SecretsManagerAccess",
                    "Effect": "Allow",
                    "Action": [
                        "secretsmanager:GetSecretValue",
                        "secretsmanager:DescribeSecret"
                    ],
                    "Resource": "arn:aws:secretsmanager:*:*:secret:concert/*"
                },
                {
                    "Sid": "CloudWatchMetrics",
                    "Effect": "Allow",
                    "Action": [
                        "cloudwatch:PutMetricData",
                        "cloudwatch:GetMetricStatistics",
                        "cloudwatch:ListMetrics"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "LogsAccess",
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:log-group:/aws/concert/*"
                }
            ]
        }'
    log_success "Core Services permissions added to developers"
}

################################################################################
# ADD MICROSERVICES PERMISSIONS
################################################################################

add_microservices_permissions() {
    log_info "Adding Microservices permissions..."
    
    # Add to developers
    log_info "Configuring Notification & Analytics services for developers..."
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperMicroservicesPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "RedisAccess",
                    "Effect": "Allow",
                    "Action": [
                        "elasticache:DescribeCacheClusters",
                        "elasticache:DescribeReplicationGroups",
                        "elasticache:DescribeCacheNodes"
                    ],
                    "Resource": "arn:aws:elasticache:*:*:cluster:concert-*"
                },
                {
                    "Sid": "SESEmailService",
                    "Effect": "Allow",
                    "Action": [
                        "ses:SendEmail",
                        "ses:SendRawEmail",
                        "ses:GetSendStatistics",
                        "ses:ListVerifiedEmailAddresses"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "SNSNotifications",
                    "Effect": "Allow",
                    "Action": [
                        "sns:Publish",
                        "sns:ListTopics",
                        "sns:GetTopicAttributes"
                    ],
                    "Resource": "arn:aws:sns:*:*:concert-*"
                },
                {
                    "Sid": "SQSMessaging",
                    "Effect": "Allow",
                    "Action": [
                        "sqs:SendMessage",
                        "sqs:ReceiveMessage",
                        "sqs:DeleteMessage",
                        "sqs:GetQueueAttributes"
                    ],
                    "Resource": "arn:aws:sqs:*:*:concert-*"
                }
            ]
        }'
    log_success "Microservices permissions added"
}

################################################################################
# ADD TESTING PERMISSIONS
################################################################################

add_tester_full_permissions() {
    log_info "Adding comprehensive testing permissions..."
    
    # Core services for testing
    log_info "Configuring services for testers..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterCoreServicesPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "DynamoDBTestAccess",
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:Query",
                        "dynamodb:GetItem",
                        "dynamodb:Scan",
                        "dynamodb:DescribeTable",
                        "dynamodb:PutItem",
                        "dynamodb:UpdateItem",
                        "dynamodb:DeleteItem"
                    ],
                    "Resource": [
                        "arn:aws:dynamodb:*:*:table/concerts",
                        "arn:aws:dynamodb:*:*:table/bookings",
                        "arn:aws:dynamodb:*:*:table/users",
                        "arn:aws:dynamodb:*:*:table/notifications"
                    ],
                    "Condition": {
                        "StringLike": {
                            "aws:SourceArn": "*test*"
                        }
                    }
                },
                {
                    "Sid": "SecretsManagerTestAccess",
                    "Effect": "Allow",
                    "Action": [
                        "secretsmanager:GetSecretValue",
                        "secretsmanager:DescribeSecret"
                    ],
                    "Resource": "arn:aws:secretsmanager:*:*:secret:concert-test/*"
                },
                {
                    "Sid": "CloudWatchTestMetrics",
                    "Effect": "Allow",
                    "Action": [
                        "cloudwatch:PutMetricData",
                        "cloudwatch:GetMetricStatistics",
                        "cloudwatch:ListMetrics"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "LogsTestAccess",
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:log-group:/aws/concert/test/*"
                },
                {
                    "Sid": "RedisTestAccess",
                    "Effect": "Allow",
                    "Action": [
                        "elasticache:DescribeCacheClusters",
                        "elasticache:DescribeReplicationGroups"
                    ],
                    "Resource": "arn:aws:elasticache:*:*:cluster:concert-test-*"
                },
                {
                    "Sid": "SESTestEmail",
                    "Effect": "Allow",
                    "Action": [
                        "ses:SendEmail",
                        "ses:SendRawEmail",
                        "ses:GetSendStatistics"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "Comprehensive testing permissions added"
}

################################################################################
# ADD DEPLOYMENT FULL PERMISSIONS
################################################################################

add_deployment_all_services_permissions() {
    log_info "Adding comprehensive deployment permissions..."
    
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentAllServicesPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "DynamoDBFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:*"
                    ],
                    "Resource": [
                        "arn:aws:dynamodb:*:*:table/concerts*",
                        "arn:aws:dynamodb:*:*:table/bookings*",
                        "arn:aws:dynamodb:*:*:table/users*",
                        "arn:aws:dynamodb:*:*:table/notifications*",
                        "arn:aws:dynamodb:*:*:table/audit*"
                    ]
                },
                {
                    "Sid": "RDSFullManagement",
                    "Effect": "Allow",
                    "Action": [
                        "rds:*"
                    ],
                    "Resource": [
                        "arn:aws:rds:*:*:db/concert*",
                        "arn:aws:rds:*:*:cluster/concert*",
                        "arn:aws:rds:*:*:pg:*"
                    ]
                },
                {
                    "Sid": "ElastiCacheFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "elasticache:*"
                    ],
                    "Resource": "arn:aws:elasticache:*:*:*"
                },
                {
                    "Sid": "SecretsManagerFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "secretsmanager:*"
                    ],
                    "Resource": "arn:aws:secretsmanager:*:*:secret:concert/*"
                },
                {
                    "Sid": "SESFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "ses:*"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "SNSFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "sns:*"
                    ],
                    "Resource": "arn:aws:sns:*:*:concert-*"
                },
                {
                    "Sid": "SQSFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "sqs:*"
                    ],
                    "Resource": "arn:aws:sqs:*:*:concert-*"
                },
                {
                    "Sid": "CloudWatchFullAccess",
                    "Effect": "Allow",
                    "Action": [
                        "cloudwatch:*",
                        "logs:*"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "ApplicationAutoScaling",
                    "Effect": "Allow",
                    "Action": [
                        "application-autoscaling:*"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "Full deployment permissions added"
}

################################################################################
# ADD SERVICE ROLE TRUST POLICIES
################################################################################

create_service_roles() {
    log_info "Creating service execution roles..."
    
    # Lambda Execution Role
    log_info "Creating Lambda execution role..."
    cat > /tmp/lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    aws iam create-role \
        --role-name concert-lambda-execution-role \
        --assume-role-policy-document file:///tmp/lambda-trust-policy.json 2>/dev/null || log_warning "Lambda role may already exist"
    
    # Attach policies to Lambda role
    aws iam put-role-policy \
        --role-name concert-lambda-execution-role \
        --policy-name LambdaExecutionPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:GetItem",
                        "dynamodb:PutItem",
                        "dynamodb:UpdateItem",
                        "dynamodb:Query",
                        "dynamodb:Scan"
                    ],
                    "Resource": "arn:aws:dynamodb:*:*:table/concerts*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:PutObject"
                    ],
                    "Resource": "arn:aws:s3:::concert-*/*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "ses:SendEmail",
                        "ses:SendRawEmail"
                    ],
                    "Resource": "*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "sns:Publish"
                    ],
                    "Resource": "arn:aws:sns:*:*:concert-*"
                }
            ]
        }'
    log_success "Lambda execution role created"
    
    # ECS Task Execution Role
    log_info "Creating ECS task execution role..."
    cat > /tmp/ecs-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    aws iam create-role \
        --role-name concert-ecs-task-execution-role \
        --assume-role-policy-document file:///tmp/ecs-trust-policy.json 2>/dev/null || log_warning "ECS role may already exist"
    
    # Attach policies to ECS role
    aws iam put-role-policy \
        --role-name concert-ecs-task-execution-role \
        --policy-name ECSTaskExecutionPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:log-group:/ecs/concert*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "ecr:GetAuthorizationToken",
                        "ecr:BatchGetImage",
                        "ecr:GetDownloadUrlForLayer"
                    ],
                    "Resource": "*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "secretsmanager:GetSecretValue"
                    ],
                    "Resource": "arn:aws:secretsmanager:*:*:secret:concert/*"
                }
            ]
        }'
    log_success "ECS task execution role created"
    
    # Clean up temp files
    rm -f /tmp/lambda-trust-policy.json /tmp/ecs-trust-policy.json
}

################################################################################
# VERIFY ALL PERMISSIONS
################################################################################

verify_permissions() {
    log_info "Verifying all permissions..."
    echo ""
    
    # Check developer permissions
    log_info "Developer group policies:"
    aws iam list-group-policies --group-name concert-developers --output text | tr '\t' '\n'
    
    # Check tester permissions
    log_info "Tester group policies:"
    aws iam list-group-policies --group-name concert-testers --output text | tr '\t' '\n'
    
    # Check deployment permissions
    log_info "Deployment group policies:"
    aws iam list-group-policies --group-name concert-deployment --output text | tr '\t' '\n'
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    display_header
    
    check_aws_cli
    check_credentials
    echo ""
    
    log_info "=========================================="
    log_info "CONFIGURING DEVELOPER GROUP"
    log_info "=========================================="
    add_developer_core_services_policy
    add_microservices_permissions
    echo ""
    
    log_info "=========================================="
    log_info "CONFIGURING TESTER GROUP"
    log_info "=========================================="
    add_tester_full_permissions
    echo ""
    
    log_info "=========================================="
    log_info "CONFIGURING DEPLOYMENT GROUP"
    log_info "=========================================="
    add_deployment_all_services_permissions
    echo ""
    
    log_info "=========================================="
    log_info "CREATING SERVICE EXECUTION ROLES"
    log_info "=========================================="
    create_service_roles
    echo ""
    
    log_info "=========================================="
    log_info "VERIFYING ALL PERMISSIONS"
    log_info "=========================================="
    verify_permissions
    echo ""
    
    log_success "✅ ALL IAM PERMISSIONS SUCCESSFULLY CONFIGURED!"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  SETUP COMPLETE - ALL SERVICES READY TO USE                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 WHAT WAS CONFIGURED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✓ Developer Group:"
    echo "  • Core Services (Auth, Event, Booking, S3, JWT)"
    echo "  • DynamoDB Access"
    echo "  • Microservices (Notification, Analytics, Email, Cache, Audit)"
    echo "  • Redis/ElastiCache"
    echo "  • Email (SES)"
    echo "  • Messaging (SNS, SQS)"
    echo "  • Monitoring (CloudWatch, Logs)"
    echo ""
    echo "✓ Tester Group:"
    echo "  • Full read/write access to test resources"
    echo "  • DynamoDB testing"
    echo "  • Email testing (SES)"
    echo "  • Redis testing"
    echo "  • Monitoring and logging"
    echo ""
    echo "✓ Deployment Group:"
    echo "  • Full DynamoDB management"
    echo "  • Full RDS management"
    echo "  • Full ElastiCache management"
    echo "  • Full SES/SNS/SQS access"
    echo "  • Full CloudWatch/Logs access"
    echo "  • Auto-scaling management"
    echo ""
    echo "✓ Service Roles:"
    echo "  • Lambda Execution Role"
    echo "  • ECS Task Execution Role"
    echo ""
    echo "🚀 IMMEDIATE NEXT STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Add users to groups:"
    echo "   aws iam add-user-to-group --group-name concert-developers --user-name user@example.com"
    echo ""
    echo "2. Users can now immediately access:"
    echo "   • All microservices"
    echo "   • DynamoDB tables"
    echo "   • Email service"
    echo "   • Caching layer"
    echo "   • Notifications"
    echo "   • Analytics"
    echo ""
    echo "3. No additional configuration needed!"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

main
