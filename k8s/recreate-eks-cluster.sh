#!/bin/bash

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"

echo "🗑️  Deleting old EKS cluster..."

# Wait for nodegroup deletion
echo "⏳ Waiting for nodegroup to delete (this takes 5-10 minutes)..."
aws eks wait nodegroup-deleted --region $REGION --cluster-name $CLUSTER_NAME --nodegroup-name concert-nodes 2>/dev/null || echo "Nodegroup already deleted"

# Delete cluster
echo "🗑️  Deleting cluster..."
aws eks delete-cluster --region $REGION --name $CLUSTER_NAME
aws eks wait cluster-deleted --region $REGION --name $CLUSTER_NAME

echo "✅ Old cluster deleted"
echo ""
echo "🚀 Creating new EKS cluster..."

# Create new cluster with eksctl (simpler)
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name concert-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

echo "✅ New cluster created!"
echo ""
echo "🔐 Granting Wav user access..."
./k8s/grant-wav-eks-access.sh

echo ""
echo "📋 Next steps:"
echo "  kubectl get nodes"
echo "  kubectl apply -f k8s/backend-deployment.yaml"
