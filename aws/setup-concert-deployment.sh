#!/bin/bash

# Complete setup for concert-deployment group with EKS permissions

set -e

GROUP_NAME="concert-deployment"
POLICY_NAME="EKSDeploymentPolicy"
POLICY_FILE="iam_eks_deployment_policy.json"

echo "🚀 Setting up concert-deployment group with EKS permissions..."
echo ""

# Step 1: Create group
echo "1️⃣ Creating IAM group: $GROUP_NAME"
aws iam create-group --group-name $GROUP_NAME 2>/dev/null && echo "✅ Group created" || echo "ℹ️  Group already exists"
echo ""

# Step 2: Create policy
echo "2️⃣ Creating IAM policy: $POLICY_NAME"
POLICY_ARN=$(aws iam create-policy \
  --policy-name $POLICY_NAME \
  --policy-document file://$POLICY_FILE \
  --description "Full EKS deployment permissions for concert platform" \
  --query 'Policy.Arn' \
  --output text 2>/dev/null || \
  aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

echo "✅ Policy ARN: $POLICY_ARN"
echo ""

# Step 3: Attach policy to group
echo "3️⃣ Attaching policy to group"
aws iam attach-group-policy \
  --group-name $GROUP_NAME \
  --policy-arn $POLICY_ARN

echo "✅ Policy attached"
echo ""

# Step 4: Verify
echo "4️⃣ Verifying setup"
aws iam list-attached-group-policies --group-name $GROUP_NAME
echo ""

echo "✨ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Add users to group:"
echo "     aws iam add-user-to-group --group-name $GROUP_NAME --user-name YOUR_USERNAME"
echo ""
echo "  2. Users can now:"
echo "     ✓ Create EKS clusters"
echo "     ✓ Manage node groups"
echo "     ✓ Push/pull ECR images"
echo "     ✓ Configure load balancers"
echo "     ✓ Setup auto-scaling"
