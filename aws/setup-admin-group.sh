#!/bin/bash

# Create concert-admin group with full AWS permissions

set -e

GROUP_NAME="concert-admin"

echo "🚀 Creating admin group: $GROUP_NAME"

# Create group
aws iam create-group --group-name $GROUP_NAME --path /teams/ 2>/dev/null && echo "✅ Group created" || echo "ℹ️  Group already exists"

# Attach AdministratorAccess policy
echo "🔗 Attaching AdministratorAccess policy..."
aws iam attach-group-policy \
  --group-name $GROUP_NAME \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "✅ Admin group configured!"
echo ""
echo "📋 Add users to admin group:"
echo "aws iam add-user-to-group --group-name $GROUP_NAME --user-name YOUR_USERNAME"
