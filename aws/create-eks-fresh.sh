#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster-v2"
REGION="ap-southeast-1"
NODE_TYPE="t4g.medium"
MIN_NODES=2
MAX_NODES=4
DESIRED_NODES=2

echo "🚀 Creating fresh EKS cluster with t4g in Singapore..."

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
echo "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
echo "./setup-github-runners.sh"
