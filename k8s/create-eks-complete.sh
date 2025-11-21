#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster"
REGION="ap-southeast-1"
ACCOUNT_ID="123456789012"

echo "🚀 Creating EKS cluster with ARM64 instances..."
echo "📝 Logging to: /tmp/eks-creation-$(date +%Y%m%d-%H%M%S).log"
echo ""

# Create cluster with eksctl
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name concert-nodes \
  --node-type t4g.micro \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed \
  --verbose 4 2>&1 | tee /tmp/eks-creation-$(date +%Y%m%d-%H%M%S).log

echo "✅ Cluster created!"
echo ""

# Update kubeconfig
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "🔐 Granting Wav user access..."

# Get the node role ARN
NODE_ROLE=$(aws eks describe-nodegroup --region $REGION --cluster-name $CLUSTER_NAME --nodegroup-name concert-nodes --query 'nodegroup.nodeRole' --output text)

# Create aws-auth ConfigMap with Wav access
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/Wav
      username: wav
      groups:
        - system:masters
  mapRoles: |
    - rolearn: ${NODE_ROLE}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

echo "✅ Wav granted admin access"
echo ""

echo "📦 Deploying backend to EKS..."

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml 2>&1 | tee -a /tmp/eks-deploy.log

echo "⏳ Waiting for LoadBalancer..."
sleep 30

# Get LoadBalancer URL
LB_URL=$(kubectl get svc concert-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Cluster Info:"
kubectl get nodes 2>&1 | tee -a /tmp/eks-deploy.log
echo ""
echo "📋 Backend Status:"
kubectl get pods 2>&1 | tee -a /tmp/eks-deploy.log
echo ""
echo "📋 Service:"
kubectl get svc concert-backend 2>&1 | tee -a /tmp/eks-deploy.log
echo ""
echo "📝 Full logs saved to: /tmp/eks-creation-*.log and /tmp/eks-deploy.log"
echo ""
echo "🌐 Backend URL: http://${LB_URL}"
echo ""
echo "📝 Update frontend with: http://${LB_URL}"
