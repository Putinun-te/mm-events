#!/bin/bash

set -e

CLUSTER_NAME="concert-cluster-v2"
REGION="ap-southeast-1"

echo "🚀 Deploying Backend with MySQL to EKS..."

# Configure kubectl
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Deploy MySQL first
echo "📦 Deploying MySQL..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        - name: MYSQL_DATABASE
          value: "concert_db"
        - name: MYSQL_USER
          value: "concert_user"
        - name: MYSQL_PASSWORD
          value: "concert_password"
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
EOF

echo "⏳ Waiting for MySQL..."
kubectl wait --for=condition=available --timeout=300s deployment/mysql

# Get backend image
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/concert-backend"

# Deploy backend
echo "📦 Deploying Backend..."
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
          value: "jdbc:mysql://mysql:3306/concert_db"
        - name: SPRING_DATASOURCE_USERNAME
          value: "concert_user"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "concert_password"
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

echo "⏳ Waiting for backend..."
kubectl wait --for=condition=available --timeout=300s deployment/concert-backend

LB_URL=$(kubectl get svc concert-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "✅ Deployed!"
echo ""
echo "🌐 Backend API: http://$LB_URL"
echo "📋 Test: curl http://$LB_URL/api/events/json"
