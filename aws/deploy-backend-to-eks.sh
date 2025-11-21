#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster-v2"
REGION="ap-southeast-1"

echo "🚀 Deploying Backend to EKS..."

# Configure kubectl
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Build backend Docker image
echo "🐳 Building backend image..."
cd ../main_backend
docker build -t concert-backend:latest .

# Tag for ECR (optional, or use Docker Hub)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/concert-backend"

# Create ECR repo if not exists
aws ecr create-repository --repository-name concert-backend --region $REGION 2>/dev/null || true

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO

# Push image
docker tag concert-backend:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# Deploy to EKS
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: concert-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: concert-backend
  template:
    metadata:
      labels:
        app: concert-backend
    spec:
      containers:
      - name: backend
        image: $ECR_REPO:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
---
apiVersion: v1
kind: Service
metadata:
  name: concert-backend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: concert-backend
EOF

echo "⏳ Waiting for LoadBalancer..."
sleep 30

LB_URL=$(kubectl get svc concert-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "✅ Backend deployed!"
echo ""
echo "🌐 Backend API: http://$LB_URL"
echo "📋 Test: curl http://$LB_URL/api/events/json"
