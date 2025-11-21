#!/bin/bash

# Setup EKS Deployment Permissions for IAM Group
# This script creates IAM policy and attaches it to deployment user group

set -e

POLICY_NAME="EKSDeploymentPolicy"
GROUP_NAME="concert-deployment"
POLICY_FILE="iam_eks_deployment_policy.json"

echo "🚀 Setting up EKS deployment permissions..."

# Create IAM policy
echo "📝 Creating IAM policy: $POLICY_NAME"
POLICY_ARN=$(aws iam create-policy \
  --policy-name $POLICY_NAME \
  --policy-document file://$POLICY_FILE \
  --description "Policy for EKS cluster deployment and management" \
  --query 'Policy.Arn' \
  --output text 2>/dev/null || \
  aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

echo "✅ Policy ARN: $POLICY_ARN"

# Attach policy to group
echo "🔗 Attaching policy to group: $GROUP_NAME"
aws iam attach-group-policy \
  --group-name $GROUP_NAME \
  --policy-arn $POLICY_ARN

echo "✅ Policy attached successfully"

# Verify attachment
echo "🔍 Verifying policy attachment..."
aws iam list-attached-group-policies --group-name $GROUP_NAME

echo ""
echo "✨ EKS deployment permissions setup complete!"
echo ""
echo "📋 Summary:"
echo "  - Policy: $POLICY_NAME"
echo "  - Group: $GROUP_NAME"
echo "  - ARN: $POLICY_ARN"
echo ""
echo "🎯 Users in '$GROUP_NAME' can now:"
echo "  ✓ Manage EKS clusters"
echo "  ✓ Push/pull images to ECR"
echo "  ✓ View networking resources"
echo "  ✓ Access CloudWatch logs"
