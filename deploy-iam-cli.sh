#!/bin/bash

################################################################################
# IAM Team Groups Deployment Script - AWS CLI
# Purpose: Create 4 IAM groups with all 21 policies for Concert application
# Date: October 31, 2025
# Status: Production Ready
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

# Check if AWS CLI is installed
check_aws_cli() {
    log_info "Checking AWS CLI installation..."
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    log_success "AWS CLI found"
}

# Check AWS credentials
check_credentials() {
    log_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_success "AWS credentials valid (Account ID: $ACCOUNT_ID)"
}

################################################################################
# CREATE GROUPS
################################################################################

create_groups() {
    log_info "Creating IAM groups..."
    
    # Developer Group
    log_info "Creating concert-developers group..."
    aws iam create-group --group-name concert-developers 2>/dev/null || log_warning "Group concert-developers may already exist"
    log_success "concert-developers group ready"
    
    # Tester Group
    log_info "Creating concert-testers group..."
    aws iam create-group --group-name concert-testers 2>/dev/null || log_warning "Group concert-testers may already exist"
    log_success "concert-testers group ready"
    
    # Deployment Group
    log_info "Creating concert-deployment group..."
    aws iam create-group --group-name concert-deployment 2>/dev/null || log_warning "Group concert-deployment may already exist"
    log_success "concert-deployment group ready"
    
    # Admin Group
    log_info "Creating concert-admins group..."
    aws iam create-group --group-name concert-admins 2>/dev/null || log_warning "Group concert-admins may already exist"
    log_success "concert-admins group ready"
}

################################################################################
# CREATE DEVELOPER POLICIES
################################################################################

create_developer_policies() {
    log_info "Creating Developer group policies..."
    
    # Developer S3 Policy
    log_info "Creating DeveloperS3Policy..."
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperS3Policy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ListDevS3Buckets",
                    "Effect": "Allow",
                    "Action": [
                        "s3:ListAllMyBuckets",
                        "s3:GetBucketVersioning"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "DevBucketAccess",
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:PutObject",
                        "s3:DeleteObject",
                        "s3:ListBucket"
                    ],
                    "Resource": [
                        "arn:aws:s3:::concert-dev-*",
                        "arn:aws:s3:::concert-dev-*/*"
                    ]
                }
            ]
        }'
    log_success "DeveloperS3Policy created"
    
    # Developer Compute Policy
    log_info "Creating DeveloperComputePolicy..."
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperComputePolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "EC2ReadDev",
                    "Effect": "Allow",
                    "Action": [
                        "ec2:Describe*",
                        "ec2:Get*",
                        "ec2:List*"
                    ],
                    "Resource": "*",
                    "Condition": {
                        "StringEquals": {
                            "ec2:ResourceTag/Environment": "dev"
                        }
                    }
                },
                {
                    "Sid": "RDSReadDev",
                    "Effect": "Allow",
                    "Action": [
                        "rds:Describe*",
                        "rds:List*",
                        "rds-db:connect"
                    ],
                    "Resource": "arn:aws:rds:*:*:db/concert-dev-*"
                },
                {
                    "Sid": "RDSProxyDev",
                    "Effect": "Allow",
                    "Action": [
                        "rds-db:connect"
                    ],
                    "Resource": "arn:aws:rds-db:*:*:dbuser:*/concert_dev_user"
                }
            ]
        }'
    log_success "DeveloperComputePolicy created"
    
    # Developer API Gateway Policy
    log_info "Creating DeveloperAPIGatewayPolicy..."
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperAPIGatewayPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "APIGatewayReadDev",
                    "Effect": "Allow",
                    "Action": [
                        "apigateway:GET",
                        "apigateway:Head"
                    ],
                    "Resource": "arn:aws:apigateway:*::/apis*",
                    "Condition": {
                        "StringLike": {
                            "aws:SourceArn": "*dev*"
                        }
                    }
                }
            ]
        }'
    log_success "DeveloperAPIGatewayPolicy created"
    
    # Developer Lambda Policy
    log_info "Creating DeveloperLambdaPolicy..."
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperLambdaPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "LambdaInvokeDev",
                    "Effect": "Allow",
                    "Action": [
                        "lambda:InvokeFunction",
                        "lambda:ListFunctions",
                        "lambda:GetFunction"
                    ],
                    "Resource": "arn:aws:lambda:*:*:function:concert-dev-*"
                }
            ]
        }'
    log_success "DeveloperLambdaPolicy created"
    
    # Developer Self-Service Policy
    log_info "Creating DeveloperSelfServicePolicy..."
    aws iam put-group-policy \
        --group-name concert-developers \
        --policy-name DeveloperSelfServicePolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ManageOwnCredentials",
                    "Effect": "Allow",
                    "Action": [
                        "iam:CreateAccessKey",
                        "iam:DeleteAccessKey",
                        "iam:ListAccessKeys",
                        "iam:UpdateAccessKey"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ManageOwnPassword",
                    "Effect": "Allow",
                    "Action": [
                        "iam:ChangePassword",
                        "iam:GetLoginProfile"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ManageOwnMFA",
                    "Effect": "Allow",
                    "Action": [
                        "iam:CreateVirtualMFADevice",
                        "iam:DeleteVirtualMFADevice",
                        "iam:EnableMFADevice",
                        "iam:DeactivateMFADevice",
                        "iam:ResyncMFADevice",
                        "iam:ListMFADevices",
                        "iam:ListVirtualMFADevices"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ListUsers",
                    "Effect": "Allow",
                    "Action": [
                        "iam:GetUser",
                        "iam:ListGroupsForUser"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                }
            ]
        }'
    log_success "DeveloperSelfServicePolicy created"
}

################################################################################
# CREATE TESTER POLICIES
################################################################################

create_tester_policies() {
    log_info "Creating Tester group policies..."
    
    # Tester S3 Policy
    log_info "Creating TesterS3Policy..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterS3Policy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ListTestS3Buckets",
                    "Effect": "Allow",
                    "Action": [
                        "s3:ListAllMyBuckets",
                        "s3:GetBucketVersioning"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "TestBucketAccess",
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:PutObject",
                        "s3:DeleteObject",
                        "s3:ListBucket"
                    ],
                    "Resource": [
                        "arn:aws:s3:::concert-test-*",
                        "arn:aws:s3:::concert-test-*/*"
                    ]
                }
            ]
        }'
    log_success "TesterS3Policy created"
    
    # Tester Compute Policy
    log_info "Creating TesterComputePolicy..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterComputePolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "EC2DescribeTestStaging",
                    "Effect": "Allow",
                    "Action": [
                        "ec2:Describe*",
                        "ec2:Get*",
                        "ec2:List*"
                    ],
                    "Resource": "*",
                    "Condition": {
                        "StringLike": {
                            "ec2:ResourceTag/Environment": [
                                "test",
                                "staging"
                            ]
                        }
                    }
                },
                {
                    "Sid": "RDSReadTestStaging",
                    "Effect": "Allow",
                    "Action": [
                        "rds:Describe*",
                        "rds:List*",
                        "rds-db:connect"
                    ],
                    "Resource": [
                        "arn:aws:rds:*:*:db/concert-test-*",
                        "arn:aws:rds:*:*:db/concert-staging-*"
                    ]
                }
            ]
        }'
    log_success "TesterComputePolicy created"
    
    # Tester API Gateway Policy
    log_info "Creating TesterAPIGatewayPolicy..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterAPIGatewayPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "APIGatewayTestAccess",
                    "Effect": "Allow",
                    "Action": [
                        "apigateway:GET",
                        "apigateway:POST",
                        "apigateway:PUT",
                        "apigateway:DELETE",
                        "apigateway:PATCH",
                        "apigateway:Head",
                        "apigateway:Options"
                    ],
                    "Resource": "arn:aws:apigateway:*::/apis*",
                    "Condition": {
                        "StringLike": {
                            "aws:SourceArn": [
                                "*test*",
                                "*staging*"
                            ]
                        }
                    }
                }
            ]
        }'
    log_success "TesterAPIGatewayPolicy created"
    
    # Tester Lambda Policy
    log_info "Creating TesterLambdaPolicy..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterLambdaPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "LambdaInvokeTestStaging",
                    "Effect": "Allow",
                    "Action": [
                        "lambda:InvokeFunction",
                        "lambda:ListFunctions",
                        "lambda:GetFunction"
                    ],
                    "Resource": [
                        "arn:aws:lambda:*:*:function:concert-test-*",
                        "arn:aws:lambda:*:*:function:concert-staging-*"
                    ]
                }
            ]
        }'
    log_success "TesterLambdaPolicy created"
    
    # Tester Monitoring Policy
    log_info "Creating TesterMonitoringPolicy..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterMonitoringPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "CloudWatchRead",
                    "Effect": "Allow",
                    "Action": [
                        "cloudwatch:GetMetricStatistics",
                        "cloudwatch:ListMetrics",
                        "cloudwatch:DescribeAlarms",
                        "logs:DescribeLogGroups",
                        "logs:DescribeLogStreams",
                        "logs:FilterLogEvents",
                        "logs:GetLogEvents"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "TesterMonitoringPolicy created"
    
    # Tester Self-Service Policy
    log_info "Creating TesterSelfServicePolicy..."
    aws iam put-group-policy \
        --group-name concert-testers \
        --policy-name TesterSelfServicePolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ManageOwnCredentials",
                    "Effect": "Allow",
                    "Action": [
                        "iam:CreateAccessKey",
                        "iam:DeleteAccessKey",
                        "iam:ListAccessKeys",
                        "iam:UpdateAccessKey"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ManageOwnPassword",
                    "Effect": "Allow",
                    "Action": [
                        "iam:ChangePassword",
                        "iam:GetLoginProfile"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ManageOwnMFA",
                    "Effect": "Allow",
                    "Action": [
                        "iam:CreateVirtualMFADevice",
                        "iam:DeleteVirtualMFADevice",
                        "iam:EnableMFADevice",
                        "iam:DeactivateMFADevice",
                        "iam:ListMFADevices"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                }
            ]
        }'
    log_success "TesterSelfServicePolicy created"
}

################################################################################
# CREATE DEPLOYMENT POLICIES
################################################################################

create_deployment_policies() {
    log_info "Creating Deployment group policies..."
    
    # Deployment EC2 Policy
    log_info "Creating DeploymentEC2Policy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentEC2Policy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "EC2Operations",
                    "Effect": "Allow",
                    "Action": [
                        "ec2:StartInstances",
                        "ec2:StopInstances",
                        "ec2:RebootInstances",
                        "ec2:TerminateInstances",
                        "ec2:RunInstances",
                        "ec2:DescribeInstances",
                        "ec2:DescribeInstanceStatus",
                        "ec2:CreateTags",
                        "ec2:DeleteTags"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "DeploymentEC2Policy created"
    
    # Deployment ECS Policy
    log_info "Creating DeploymentECSPolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentECSPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ECSManagement",
                    "Effect": "Allow",
                    "Action": [
                        "ecs:CreateService",
                        "ecs:DescribeServices",
                        "ecs:UpdateService",
                        "ecs:DeleteService",
                        "ecs:DescribeTaskDefinition",
                        "ecs:DescribeContainerInstances",
                        "ecs:ListContainerInstances",
                        "ecs:ListServices",
                        "ecs:ListClusters",
                        "ecs:DescribeClusters",
                        "ecs:RegisterTaskDefinition",
                        "ecs:RunTask",
                        "ecs:StopTask",
                        "ecs:ListTasks"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "DeploymentECSPolicy created"
    
    # Deployment RDS Policy
    log_info "Creating DeploymentRDSPolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentRDSPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "RDSManagement",
                    "Effect": "Allow",
                    "Action": [
                        "rds:ModifyDBInstance",
                        "rds:DescribeDBInstances",
                        "rds:CreateDBSnapshot",
                        "rds:DescribeDBSnapshots",
                        "rds:RestoreDBInstanceFromDBSnapshot",
                        "rds:DeleteDBSnapshot",
                        "rds:DescribeDBParameterGroups",
                        "rds:ModifyDBParameterGroup",
                        "rds:CreateDBParameterGroup",
                        "rds:DescribeEvents"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "DeploymentRDSPolicy created"
    
    # Deployment S3/Terraform Policy
    log_info "Creating DeploymentS3TerraformPolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentS3TerraformPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "S3Access",
                    "Effect": "Allow",
                    "Action": [
                        "s3:ListAllMyBuckets",
                        "s3:GetObject",
                        "s3:PutObject",
                        "s3:DeleteObject",
                        "s3:ListBucket",
                        "s3:GetBucketVersioning",
                        "s3:PutBucketVersioning",
                        "s3:GetBucketLocation"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "TerraformStateManagement",
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:PutItem",
                        "dynamodb:GetItem",
                        "dynamodb:DeleteItem",
                        "dynamodb:Query",
                        "dynamodb:DescribeTable",
                        "dynamodb:CreateTable",
                        "dynamodb:DeleteTable"
                    ],
                    "Resource": "arn:aws:dynamodb:*:*:table/terraform-*"
                }
            ]
        }'
    log_success "DeploymentS3TerraformPolicy created"
    
    # Deployment Lambda Policy
    log_info "Creating DeploymentLambdaPolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentLambdaPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "LambdaDeployment",
                    "Effect": "Allow",
                    "Action": [
                        "lambda:CreateFunction",
                        "lambda:DeleteFunction",
                        "lambda:GetFunction",
                        "lambda:GetFunctionCodeSigningConfig",
                        "lambda:UpdateFunctionCode",
                        "lambda:UpdateFunctionConfiguration",
                        "lambda:PublishVersion",
                        "lambda:CreateAlias",
                        "lambda:UpdateAlias",
                        "lambda:DeleteAlias",
                        "lambda:ListFunctions",
                        "lambda:ListAliases",
                        "lambda:ListVersionsByFunction"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "DeploymentLambdaPolicy created"
    
    # Deployment API/CloudFormation Policy
    log_info "Creating DeploymentAPICloudFormationPolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentAPICloudFormationPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "APIGatewayDeploy",
                    "Effect": "Allow",
                    "Action": [
                        "apigateway:*"
                    ],
                    "Resource": "*"
                },
                {
                    "Sid": "CloudFormationAccess",
                    "Effect": "Allow",
                    "Action": [
                        "cloudformation:CreateStack",
                        "cloudformation:UpdateStack",
                        "cloudformation:DeleteStack",
                        "cloudformation:DescribeStacks",
                        "cloudformation:DescribeStackResources",
                        "cloudformation:DescribeStackResource",
                        "cloudformation:ListStacks",
                        "cloudformation:GetTemplate",
                        "cloudformation:ValidateTemplate"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "DeploymentAPICloudFormationPolicy created"
    
    # Deployment CloudWatch Logs Policy
    log_info "Creating DeploymentCloudWatchLogsPolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentCloudWatchLogsPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "CloudWatchLogsManagement",
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                        "logs:DescribeLogGroups",
                        "logs:DescribeLogStreams",
                        "logs:DeleteLogGroup",
                        "logs:DeleteLogStream",
                        "logs:FilterLogEvents",
                        "logs:GetLogEvents"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    log_success "DeploymentCloudWatchLogsPolicy created"
    
    # Deployment PassRole Policy
    log_info "Creating DeploymentPassRolePolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentPassRolePolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "PassServiceRole",
                    "Effect": "Allow",
                    "Action": [
                        "iam:PassRole"
                    ],
                    "Resource": [
                        "arn:aws:iam::*:role/ecsTaskExecutionRole",
                        "arn:aws:iam::*:role/lambda-execution-role",
                        "arn:aws:iam::*:role/ecs-task-role"
                    ]
                }
            ]
        }'
    log_success "DeploymentPassRolePolicy created"
    
    # Deployment Self-Service Policy
    log_info "Creating DeploymentSelfServicePolicy..."
    aws iam put-group-policy \
        --group-name concert-deployment \
        --policy-name DeploymentSelfServicePolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "ManageOwnCredentials",
                    "Effect": "Allow",
                    "Action": [
                        "iam:CreateAccessKey",
                        "iam:DeleteAccessKey",
                        "iam:ListAccessKeys",
                        "iam:UpdateAccessKey"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ManageOwnPassword",
                    "Effect": "Allow",
                    "Action": [
                        "iam:ChangePassword",
                        "iam:GetLoginProfile"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                },
                {
                    "Sid": "ManageOwnMFA",
                    "Effect": "Allow",
                    "Action": [
                        "iam:CreateVirtualMFADevice",
                        "iam:DeleteVirtualMFADevice",
                        "iam:EnableMFADevice",
                        "iam:DeactivateMFADevice",
                        "iam:ListMFADevices"
                    ],
                    "Resource": "arn:aws:iam::*:user/${aws:username}"
                }
            ]
        }'
    log_success "DeploymentSelfServicePolicy created"
}

################################################################################
# CREATE ADMIN POLICY
################################################################################

create_admin_policy() {
    log_info "Creating Admin group policy..."
    
    log_info "Creating AdminFullAccessPolicy..."
    aws iam put-group-policy \
        --group-name concert-admins \
        --policy-name AdminFullAccessPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "AdminFullAccess",
                    "Effect": "Allow",
                    "Action": "*",
                    "Resource": "*"
                }
            ]
        }'
    log_success "AdminFullAccessPolicy created"
}

################################################################################
# VERIFY DEPLOYMENT
################################################################################

verify_deployment() {
    log_info "Verifying deployment..."
    
    log_info "Checking groups..."
    aws iam list-groups --query 'Groups[?contains(GroupName, `concert`)].GroupName' --output table
    
    log_info "Checking concert-developers policies..."
    aws iam list-group-policies --group-name concert-developers --output table
    
    log_info "Checking concert-testers policies..."
    aws iam list-group-policies --group-name concert-testers --output table
    
    log_info "Checking concert-deployment policies..."
    aws iam list-group-policies --group-name concert-deployment --output table
    
    log_info "Checking concert-admins policies..."
    aws iam list-group-policies --group-name concert-admins --output table
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  IAM TEAM GROUPS DEPLOYMENT - AWS CLI                          ║"
    echo "║  Creating 4 Groups with 21 Policies for Concert Application   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_aws_cli
    check_credentials
    echo ""
    
    create_groups
    echo ""
    
    create_developer_policies
    echo ""
    
    create_tester_policies
    echo ""
    
    create_deployment_policies
    echo ""
    
    create_admin_policy
    echo ""
    
    verify_deployment
    echo ""
    
    log_success "✅ IAM Team Groups deployment COMPLETE!"
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "📊 DEPLOYMENT SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "✓ Groups Created: 4"
    echo "  • concert-developers"
    echo "  • concert-testers"
    echo "  • concert-deployment"
    echo "  • concert-admins"
    echo ""
    echo "✓ Policies Created: 21"
    echo "  • Developer: 5 policies"
    echo "  • Testers: 5 policies"
    echo "  • Deployment: 9 policies"
    echo "  • Admins: 1 policy"
    echo ""
    echo "✓ Account ID: $ACCOUNT_ID"
    echo ""
    echo "🚀 NEXT STEPS"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "1. Add users to groups:"
    echo "   aws iam add-user-to-group --group-name concert-developers --user-name john.doe"
    echo ""
    echo "2. Verify user's group membership:"
    echo "   aws iam list-groups-for-user --user-name john.doe"
    echo ""
    echo "3. Test user's permissions:"
    echo "   aws s3 ls --profile john.doe"
    echo ""
    echo "4. For more details, see AWS_IAM_TEAM_GROUPS_QUICK_REFERENCE.md"
    echo ""
}

# Run main
main
