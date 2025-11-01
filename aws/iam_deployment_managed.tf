# Deployment Group - Use AWS Managed Policies to avoid inline policy size limits
# This replaces the 14 inline policies that exceed the 5120 byte limit

# Attach AWS managed policies for common deployment tasks
resource "aws_iam_group_policy_attachment" "deployment_power_user" {
  group      = aws_iam_group.deployment.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Additional IAM permissions (PowerUserAccess doesn't include IAM)
resource "aws_iam_group_policy" "deployment_iam_limited" {
  name  = "${var.project_name}-deployment-iam-limited"
  group = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PassRoleToServices"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ecs-tasks.amazonaws.com",
              "lambda.amazonaws.com",
              "rds.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "ManageServiceLinkedRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole",
          "iam:GetServiceLinkedRoleDeletionStatus"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/*"
      }
    ]
  })
}

# Self-service password and MFA management
resource "aws_iam_group_policy" "deployment_self_service" {
  name  = "${var.project_name}-deployment-self-service"
  group = aws_iam_group.deployment.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:GetAccountSummary",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnPasswords"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnAccessKeys"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey"
        ]
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      },
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:DeactivateMFADevice"
        ]
        Resource = [
          "arn:aws:iam::*:mfa/$${aws:username}",
          "arn:aws:iam::*:user/$${aws:username}"
        ]
      }
    ]
  })
}
