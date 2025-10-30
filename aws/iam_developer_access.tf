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

# ============================================================================
# IAM TEAM GROUPS - COMPREHENSIVE RBAC FOR CONCERT APPLICATION
# ============================================================================

# IAM Group for Developers
resource "aws_iam_group" "developers" {
  name        = "${var.project_name}-developers"
  path        = "/teams/"
  description = "Developer team - Code development, local testing, and feature branches"

  tags = {
    Team        = "Development"
    Purpose     = "Application Development"
    Environment = "dev"
  }
}

# IAM Group for Testers
resource "aws_iam_group" "testers" {
  name        = "${var.project_name}-testers"
  path        = "/teams/"
  description = "QA/Testing team - Test environment access, test data management, reporting"

  tags = {
    Team        = "QA"
    Purpose     = "Quality Assurance"
    Environment = "test"
  }
}

# IAM Group for Deployment/DevOps
resource "aws_iam_group" "deployment" {
  name        = "${var.project_name}-deployment"
  path        = "/teams/"
  description = "Deployment/DevOps team - CI/CD pipelines, infrastructure updates, deployments"

  tags = {
    Team        = "DevOps"
    Purpose     = "Deployment Operations"
    Environment = "all"
  }
}

# IAM Group for Admins
resource "aws_iam_group" "admins" {
  name        = "${var.project_name}-admins"
  path        = "/teams/"
  description = "Administrator team - Full AWS access for infrastructure and security management"

  tags = {
    Team        = "Administration"
    Purpose     = "Infrastructure Administration"
    Environment = "all"
    Sensitive   = "true"
  }
}

# ============================================================================
# DEVELOPER GROUP POLICIES
# ============================================================================

# IAM Policy for Developer S3 Access
resource "aws_iam_group_policy" "developer_s3_policy" {
  name   = "${var.project_name}-developer-s3-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3DevelopmentBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${aws_s3_bucket.event_pictures.arn}",
          "${aws_s3_bucket.event_pictures.arn}/*",
          "${aws_s3_bucket.user_avatars.arn}",
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

# Developer - EC2 and RDS Access
resource "aws_iam_group_policy" "developer_compute_policy" {
  name   = "${var.project_name}-developer-compute-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2DevelopmentAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Environment" = "dev"
          }
        }
      },
      {
        Sid    = "RDSReadAccess"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "rds:ResourceTag/Environment" = "dev"
          }
        }
      }
    ]
  })
}

# Developer - API Gateway and Lambda Access
resource "aws_iam_group_policy" "developer_apigateway_policy" {
  name   = "${var.project_name}-developer-apigateway-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "APIGatewayReadAccess"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:HEAD",
          "apigateway:OPTIONS"
        ]
        Resource = "arn:aws:apigateway:${var.aws_region}::/restapis/*"
      },
      {
        Sid    = "LambdaInvokeAccess"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction",
          "lambda:ListFunctions"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*-dev"
      }
    ]
  })
}

# Developer - Lambda Invocation
resource "aws_iam_group_policy" "developer_lambda_policy" {
  name   = "${var.project_name}-developer-lambda-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaInvoke"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*-dev"
      }
    ]
  })
}

# Developer - CloudWatch Logs Access
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

# Developer - Self-Service Credentials
resource "aws_iam_group_policy" "developer_self_service_policy" {
  name   = "${var.project_name}-developer-self-service-policy"
  group  = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ViewOwnCredentials"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:ListSigningCertificates",
          "iam:GetLoginProfile"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      },
      {
        Sid    = "ManageOwnMFADevice"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/$${aws:username}"
      },
      {
        Sid    = "ManageOwnAccessKeys"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "iam:GetAccessKeyLastUsed"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      },
      {
        Sid    = "ManageOwnPassword"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      }
    ]
  })
}

# ============================================================================
# TESTER GROUP POLICIES
# ============================================================================

# Tester - S3 Test Access
resource "aws_iam_group_policy" "tester_s3_policy" {
  name   = "${var.project_name}-tester-s3-policy"
  group  = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3TestBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.event_pictures.arn}-test",
          "${aws_s3_bucket.event_pictures.arn}-test/*",
          "${aws_s3_bucket.user_avatars.arn}-test",
          "${aws_s3_bucket.user_avatars.arn}-test/*"
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

# Tester - EC2 and RDS Test Access
resource "aws_iam_group_policy" "tester_compute_policy" {
  name   = "${var.project_name}-tester-compute-policy"
  group  = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2TestEnvironmentAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Environment" = ["test", "staging"]
          }
        }
      },
      {
        Sid    = "RDSTestAccess"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "rds:ResourceTag/Environment" = ["test", "staging"]
          }
        }
      }
    ]
  })
}

# Tester - API Gateway and Lambda Test Access
resource "aws_iam_group_policy" "tester_api_policy" {
  name   = "${var.project_name}-tester-api-policy"
  group  = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "APIGatewayTestAccess"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:HEAD",
          "apigateway:OPTIONS",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:DELETE"
        ]
        Resource = "*"
      },
      {
        Sid    = "LambdaTestInvoke"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction",
          "lambda:ListFunctions"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*-test"
      }
    ]
  })
}

# Tester - CloudWatch and Monitoring
resource "aws_iam_group_policy" "tester_monitoring_policy" {
  name   = "${var.project_name}-tester-monitoring-policy"
  group  = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsRead"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/concert/*"
      },
      {
        Sid    = "CloudWatchMetricsRead"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

# Tester - Self-Service Credentials
resource "aws_iam_group_policy" "tester_self_service_policy" {
  name   = "${var.project_name}-tester-self-service-policy"
  group  = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ViewOwnCredentials"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:GetLoginProfile"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      }
    ]
  })
}

# ============================================================================
# DEPLOYMENT GROUP POLICIES
# ============================================================================

# Deployment - EC2 Instance Management
resource "aws_iam_group_policy" "deployment_ec2_policy" {
  name   = "${var.project_name}-deployment-ec2-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2InstanceManagement"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Deployment - ECS Task Management
resource "aws_iam_group_policy" "deployment_ecs_policy" {
  name   = "${var.project_name}-deployment-ecs-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSTaskExecution"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:ListServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          "ecs:RunTask",
          "ecs:StopTask"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-*",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-*",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}-*:*"
        ]
      }
    ]
  })
}

# Deployment - RDS Management
resource "aws_iam_group_policy" "deployment_rds_policy" {
  name   = "${var.project_name}-deployment-rds-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RDSManagement"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots",
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:ListTagsForResource",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# Deployment - S3 and Terraform State
resource "aws_iam_group_policy" "deployment_s3_terraform_policy" {
  name   = "${var.project_name}-deployment-s3-terraform-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3DeploymentAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetObjectVersion",
          "s3:PutBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*-dev/*",
          "arn:aws:s3:::${var.project_name}-*-dev",
          "arn:aws:s3:::${var.project_name}-*-test/*",
          "arn:aws:s3:::${var.project_name}-*-test",
          "arn:aws:s3:::${var.project_name}-*-staging/*",
          "arn:aws:s3:::${var.project_name}-*-staging"
        ]
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-terraform-state",
          "arn:aws:s3:::${var.project_name}-terraform-state/*"
        ]
      },
      {
        Sid    = "DynamoDBStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-terraform-lock"
      }
    ]
  })
}

# Deployment - Lambda Deployment
resource "aws_iam_group_policy" "deployment_lambda_policy" {
  name   = "${var.project_name}-deployment-lambda-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaDeployment"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PublishVersion",
          "lambda:CreateAlias",
          "lambda:UpdateAlias",
          "lambda:DeleteAlias",
          "lambda:GetFunction",
          "lambda:ListFunctions",
          "lambda:ListVersionsByFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      }
    ]
  })
}

# Deployment - API Gateway and CloudFormation
resource "aws_iam_group_policy" "deployment_api_cf_policy" {
  name   = "${var.project_name}-deployment-api-cf-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "APIGatewayDeployment"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:PATCH",
          "apigateway:DELETE",
          "apigateway:CreateDeployment",
          "apigateway:UpdateStage"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudFormationManagement"
        Effect = "Allow"
        Action = [
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackEvents",
          "cloudformation:DescribeStackResource",
          "cloudformation:DescribeStackResources",
          "cloudformation:GetTemplate",
          "cloudformation:ListStacks",
          "cloudformation:ListStackResources",
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:DeleteStack"
        ]
        Resource = "arn:aws:cloudformation:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stack/${var.project_name}-*"
      }
    ]
  })
}

# Deployment - IAM PassRole (limited)
resource "aws_iam_group_policy" "deployment_pass_role_policy" {
  name   = "${var.project_name}-deployment-pass-role-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PassRoleForServices"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskRole",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-lambda-execution-role"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com",
              "lambda.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# Deployment - CloudWatch Logs
resource "aws_iam_group_policy" "deployment_logs_policy" {
  name   = "${var.project_name}-deployment-logs-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*"
      }
    ]
  })
}

# Deployment - Self-Service Credentials
resource "aws_iam_group_policy" "deployment_self_service_policy" {
  name   = "${var.project_name}-deployment-self-service-policy"
  group  = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ViewOwnCredentials"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListAccessKeys",
          "iam:GetLoginProfile"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      }
    ]
  })
}

# ============================================================================
# ADMIN GROUP POLICY
# ============================================================================

# Admin - Full Access
resource "aws_iam_group_policy_attachment" "admins_policy" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# USER TEMPLATES AND MEMBERSHIP
# ============================================================================

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

output "developer_group_arn" {
  value       = aws_iam_group.developers.arn
  description = "ARN of the Developers group"
}

output "tester_group_name" {
  value       = aws_iam_group.testers.name
  description = "IAM group name for testers - add users to this group"
}

output "tester_group_arn" {
  value       = aws_iam_group.testers.arn
  description = "ARN of the Testers group"
}

output "deployment_group_name" {
  value       = aws_iam_group.deployment.name
  description = "IAM group name for deployment engineers - add users to this group"
}

output "deployment_group_arn" {
  value       = aws_iam_group.deployment.arn
  description = "ARN of the Deployment group"
}

output "admin_group_name" {
  value       = aws_iam_group.admins.name
  description = "IAM group name for admins - add users to this group"
}

output "admin_group_arn" {
  value       = aws_iam_group.admins.arn
  description = "ARN of the Admins group"
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
