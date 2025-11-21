#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster-v2"
REGION="ap-southeast-1"
RDS_ENDPOINT="concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com"

echo "🚀 Deploying Backend with RDS..."

# Configure kubectl
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Get backend image
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/concert-backend"

# Delete old deployment
kubectl delete deployment concert-backend 2>/dev/null || true

# Deploy backend with RDS
kubectl apply -f - <<EOF
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
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://$RDS_ENDPOINT:3306/concert_db"
        - name: SPRING_DATASOURCE_USERNAME
          value: "admin"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "REDACTED_PASSWORD_A"
EOF

echo "⏳ Waiting for backend..."
kubectl wait --for=condition=available --timeout=300s deployment/concert-backend

LB_URL=$(kubectl get svc concert-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "✅ Deployed!"
echo ""
echo "🌐 Backend API: http://$LB_URL"
echo "📋 Test: curl http://$LB_URL/api/events/json"
