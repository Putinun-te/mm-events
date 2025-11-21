#!/bin/bash

# Create concert-deployment IAM group and setup permissions

set -e

GROUP_NAME="concert-deployment"

echo "🚀 Creating IAM group: $GROUP_NAME"

# Create group
aws iam create-group --group-name $GROUP_NAME 2>/dev/null || echo "Group already exists"

# Attach EKS policy
echo "🔗 Attaching EKS deployment policy..."
./setup-eks-permissions.sh

echo "✅ Group $GROUP_NAME created and configured!"
echo ""
echo "📋 Add users to group:"
echo "aws iam add-user-to-group --group-name $GROUP_NAME --user-name USERNAME"
