# EKS Deployment Guide

## Prerequisites

- AWS CLI configured
- kubectl installed
- Docker installed
- IAM permissions setup (see below)

## IAM Permissions Setup

### 1. Create EKS Deployment Policy

```bash
cd aws
chmod +x setup-eks-permissions.sh
./setup-eks-permissions.sh
```

This creates and attaches the EKS deployment policy to your `deployment-users` group.

### 2. Manual Policy Creation (Alternative)

```bash
aws iam create-policy \
  --policy-name EKSDeploymentPolicy \
  --policy-document file://iam_eks_deployment_policy.json

aws iam attach-group-policy \
  --group-name concert-deployment \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/EKSDeploymentPolicy
```

## EKS Cluster Setup

### 1. Create EKS Cluster

```bash
eksctl create cluster \
  --name concert-cluster \
  --region ap-southeast-1 \
  --nodegroup-name concert-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name concert-cluster
kubectl get nodes
```

## ECR Repository Setup

### 1. Create ECR Repositories

```bash
aws ecr create-repository --repository-name concert-backend --region ap-southeast-1
aws ecr create-repository --repository-name concert-frontend --region ap-southeast-1
```

### 2. Login to ECR

```bash
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com
```

## Build and Push Images

### Backend

```bash
cd main_backend
docker build -t concert-backend .
docker tag concert-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/concert-backend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/concert-backend:latest
```

### Frontend

```bash
cd main_frontend/concert1
docker build -t concert-frontend .
docker tag concert-frontend:latest YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/concert-frontend:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/concert-frontend:latest
```

## Deploy to EKS

### 1. Create Kubernetes Manifests

Create `k8s/deployment.yaml`:

```yaml
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
        image: YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/concert-backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://YOUR_RDS_ENDPOINT:3306/concert_db"
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
```

### 2. Apply Manifests

```bash
kubectl apply -f k8s/deployment.yaml
kubectl get pods
kubectl get services
```

## Monitoring

```bash
# View logs
kubectl logs -f deployment/concert-backend

# Check pod status
kubectl get pods -w

# Describe pod
kubectl describe pod POD_NAME
```

## Scaling

```bash
# Manual scaling
kubectl scale deployment concert-backend --replicas=3

# Auto-scaling
kubectl autoscale deployment concert-backend --cpu-percent=70 --min=2 --max=5
```

## Cleanup

```bash
kubectl delete -f k8s/deployment.yaml
eksctl delete cluster --name concert-cluster --region ap-southeast-1
```

## Permissions Summary

The EKS deployment policy grants:

- ✅ EKS cluster management
- ✅ ECR image push/pull
- ✅ EC2 networking view
- ✅ Load balancer management
- ✅ CloudWatch logs access
- ✅ Auto-scaling view

## Troubleshooting

### Cannot access cluster
```bash
aws eks update-kubeconfig --region ap-southeast-1 --name concert-cluster
```

### Image pull errors
```bash
kubectl create secret docker-registry ecr-secret \
  --docker-server=YOUR_ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-southeast-1)
```

### Pod not starting
```bash
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```
