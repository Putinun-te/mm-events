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
  name = "${var.project_name}-backend-s3-policy"
  role = aws_iam_role.backend_ec2_role.id

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
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          "${aws_s3_bucket.event_pictures.arn}/*",
          "${aws_s3_bucket.user_avatars.arn}/*"
        ]
      },
      {
        Sid    = "S3MultipartUpload"
        Effect = "Allow"
        Action = [
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          aws_s3_bucket.event_pictures.arn,
          aws_s3_bucket.user_avatars.arn
        ]
      }
    ]
  })
}

# Policy for SSM Session Manager
resource "aws_iam_role_policy" "backend_ssm_policy" {
  name = "${var.project_name}-backend-ssm-policy"
  role = aws_iam_role.backend_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMSessionManager"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsForSSM"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/concert/*"
      }
    ]
  })
}

# Policy for ElastiCache access (if needed by application)
resource "aws_iam_role_policy" "backend_elasticache_policy" {
  name = "${var.project_name}-backend-elasticache-policy"
  role = aws_iam_role.backend_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElastiCacheDescribe"
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for CloudWatch Metrics
resource "aws_iam_role_policy" "backend_cloudwatch_policy" {
  name = "${var.project_name}-backend-cloudwatch-policy"
  role = aws_iam_role.backend_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for Secrets Manager (for DB credentials)
resource "aws_iam_role_policy" "backend_secrets_policy" {
  name = "${var.project_name}-backend-secrets-policy"
  role = aws_iam_role.backend_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerGetValue"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/*"
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
  name = "${var.project_name}-developers"
  path = "/teams/"
}

# IAM Group for Testers
resource "aws_iam_group" "testers" {
  name = "${var.project_name}-testers"
  path = "/teams/"
}

# IAM Group for Deployment/DevOps
resource "aws_iam_group" "deployment" {
  name = "${var.project_name}-deployment"
  path = "/teams/"
}

# IAM Group for Admins
resource "aws_iam_group" "admins" {
  name = "${var.project_name}-admins"
  path = "/teams/"
}

# ============================================================================
# DEVELOPER GROUP POLICIES
# ============================================================================

# IAM Policy for Developer S3 Access
resource "aws_iam_group_policy" "developer_s3_policy" {
  name  = "${var.project_name}-developer-s3-policy"
  group = aws_iam_group.developers.name

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
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
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
  name  = "${var.project_name}-developer-compute-policy"
  group = aws_iam_group.developers.name

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
  name  = "${var.project_name}-developer-apigateway-policy"
  group = aws_iam_group.developers.name

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
  name  = "${var.project_name}-developer-lambda-policy"
  group = aws_iam_group.developers.name

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
  name  = "${var.project_name}-developer-logs-policy"
  group = aws_iam_group.developers.name

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
          "logs:FilterLogEvents",
          "logs:TailLogStream"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/concert/*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/concert/*"
        ]
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetDashboard",
          "cloudwatch:ListDashboards"
        ]
        Resource = "*"
      }
    ]
  })
}

# Developer - ElastiCache Access
resource "aws_iam_group_policy" "developer_elasticache_policy" {
  name  = "${var.project_name}-developer-elasticache-policy"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElastiCacheRead"
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:DescribeReplicationGroups",
          "elasticache:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# Developer - ECR Access
resource "aws_iam_group_policy" "developer_ecr_policy" {
  name  = "${var.project_name}-developer-ecr-policy"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRRepositoryAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

# Developer - Cognito Access
resource "aws_iam_group_policy" "developer_cognito_policy" {
  name  = "${var.project_name}-developer-cognito-policy"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CognitoUserPoolRead"
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPool",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:ListUsers",
          "cognito-idp:AdminGetUser",
          "cognito-idp:ListUserPoolClients",
          "cognito-idp:ListUserPools"
        ]
        Resource = "*"
      }
    ]
  })
}

# Developer - Secrets Manager Read Access
resource "aws_iam_group_policy" "developer_secrets_policy" {
  name  = "${var.project_name}-developer-secrets-policy"
  group = aws_iam_group.developers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/*"
      }
    ]
  })
}

# Developer - Self-Service Credentials
resource "aws_iam_group_policy" "developer_self_service_policy" {
  name  = "${var.project_name}-developer-self-service-policy"
  group = aws_iam_group.developers.name

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
  name  = "${var.project_name}-tester-s3-policy"
  group = aws_iam_group.testers.name

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
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
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
  name  = "${var.project_name}-tester-compute-policy"
  group = aws_iam_group.testers.name

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
  name  = "${var.project_name}-tester-api-policy"
  group = aws_iam_group.testers.name

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
  name  = "${var.project_name}-tester-monitoring-policy"
  group = aws_iam_group.testers.name

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
  name  = "${var.project_name}-tester-self-service-policy"
  group = aws_iam_group.testers.name

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

# Tester - ElastiCache Read Access
resource "aws_iam_group_policy" "tester_elasticache_policy" {
  name  = "${var.project_name}-tester-elasticache-policy"
  group = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ElastiCacheTestRead"
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:DescribeReplicationGroups",
          "elasticache:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# Tester - Cognito Test Access
resource "aws_iam_group_policy" "tester_cognito_policy" {
  name  = "${var.project_name}-tester-cognito-policy"
  group = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CognitoTestAccess"
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPool",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:ListUsers",
          "cognito-idp:AdminGetUser",
          "cognito-idp:ListUserPoolClients",
          "cognito-idp:ListUserPools"
        ]
        Resource = "*"
      }
    ]
  })
}

# Tester - Secrets Manager Read Access
resource "aws_iam_group_policy" "tester_secrets_policy" {
  name  = "${var.project_name}-tester-secrets-policy"
  group = aws_iam_group.testers.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerTestRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}-test-*"
      }
    ]
  })
}

# ============================================================================
# DEPLOYMENT GROUP POLICIES
# ============================================================================

# NOTE: Deployment group inline policies have been moved to iam_deployment_managed.tf
# This avoids the AWS IAM group inline policy size limit (5120 bytes total)
# The old inline policies are preserved in iam_deployment_inline_policies.tf.disabled
# New approach uses AWS PowerUserAccess managed policy + minimal inline policies

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

# Note: aws_caller_identity data source is defined in main.tf
