#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"

echo "🗑️  Deleting EKS cluster: $CLUSTER_NAME in $REGION..."

eksctl delete cluster --name $CLUSTER_NAME --region $REGION --wait

echo "✅ Cluster deleted successfully!"
