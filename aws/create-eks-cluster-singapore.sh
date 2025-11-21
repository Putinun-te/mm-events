#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"
NODE_TYPE="t3.medium"
MIN_NODES=2
MAX_NODES=4
DESIRED_NODES=2

echo "🚀 Creating EKS cluster in Singapore (${REGION})..."

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    echo "❌ eksctl not found. Install it first:"
    echo "brew install eksctl"
    exit 1
fi

# Create cluster
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name concert-nodes \
  --node-type $NODE_TYPE \
  --nodes $DESIRED_NODES \
  --nodes-min $MIN_NODES \
  --nodes-max $MAX_NODES \
  --managed

echo "✅ Cluster created successfully!"
echo ""
echo "📋 Configure kubectl:"
echo "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
