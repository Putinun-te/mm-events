#!/bin/bash

set -e

REGION="ap-southeast-1"
STACK_NAME="eksctl-concert-cluster-cluster"

echo "🔍 Checking what failed..."
aws cloudformation describe-stack-events --stack-name $STACK_NAME --region $REGION --max-items 10 --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' --output table

echo ""
echo "🔨 Force deleting stack (retain failed resources)..."
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION --retain-resources $(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --region $REGION --query 'StackResources[?ResourceStatus==`DELETE_FAILED`].LogicalResourceId' --output text)

echo "✅ Force delete initiated. Wait 2 minutes then run: ./create-eks-cluster-singapore.sh"
