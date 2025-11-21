#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"
NODE_TYPE="t4g.medium"  # ARM-based, 20% cheaper than t3
MIN_NODES=2
MAX_NODES=4
DESIRED_NODES=2

echo "🚀 Creating EKS cluster with t4g (ARM) in Singapore..."

eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name concert-nodes \
  --node-type $NODE_TYPE \
  --nodes $DESIRED_NODES \
  --nodes-min $MIN_NODES \
  --nodes-max $MAX_NODES \
  --managed

echo "✅ Cluster created!"
echo ""
echo "📋 Configure kubectl:"
echo "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
echo ""
echo "🏃 Next: Install GitHub Actions Runner Controller"
echo "./setup-github-runners.sh"
