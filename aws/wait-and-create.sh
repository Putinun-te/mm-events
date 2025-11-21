#!/bin/bash

set -e

REGION="ap-southeast-1"

echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name eksctl-concert-cluster-cluster --region $REGION

echo "✅ Stack deleted! Creating cluster now..."
./create-eks-cluster-singapore.sh
