#!/bin/bash

set -e

REGION="ap-southeast-1"

echo "🧹 Cleaning up failed CloudFormation stacks..."

# Delete all eksctl-concert-cluster stacks
for stack in $(aws cloudformation list-stacks --region $REGION --stack-status-filter CREATE_FAILED ROLLBACK_COMPLETE CREATE_COMPLETE --query "StackSummaries[?starts_with(StackName, 'eksctl-concert-cluster')].StackName" --output text); do
    echo "Deleting stack: $stack"
    aws cloudformation delete-stack --stack-name $stack --region $REGION
done

echo "⏳ Waiting for stacks to delete..."
sleep 10

echo "✅ Cleanup complete! Now run: ./create-eks-cluster-singapore.sh"
