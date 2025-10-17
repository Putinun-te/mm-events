#!/bin/bash
# Local Kubernetes Deployment Script for Docker Desktop
# This script builds images locally and deploys to local K8s cluster

set -e  # Exit on error

echo "🚀 Concert Platform - Local K8s Deployment"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker Desktop K8s is running
echo "📋 Checking prerequisites..."
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Error: Kubernetes cluster not accessible${NC}"
    echo "Please ensure Docker Desktop Kubernetes is running"
    exit 1
fi

CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "docker-desktop" ]; then
    echo -e "${YELLOW}⚠️  Warning: Current context is '$CURRENT_CONTEXT'${NC}"
    echo -e "${YELLOW}   This script is designed for Docker Desktop${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✅ Kubernetes cluster accessible${NC}"
echo ""

# Build backend image
echo "🏗️  Step 1/6: Building backend image..."
cd main_backend
docker build -t concert-backend:latest -f Dockerfile.k8s .
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Backend build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Backend image built${NC}"
cd ..
echo ""

# Build frontend image
echo "🏗️  Step 2/6: Building frontend image..."
cd main_frontend/concert1
docker build -t concert-frontend:latest -f Dockerfile.k8s .
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Frontend image built${NC}"
cd ../..
echo ""

# Apply K8s manifests in order
echo "📦 Step 3/6: Creating namespace..."
kubectl apply -f k8s/namespace.yaml
echo ""

echo "📦 Step 4/6: Creating ConfigMap and Secrets..."
kubectl apply -f k8s/configmap.yaml
echo ""

echo "📦 Step 5/6: Deploying MySQL..."
kubectl apply -f k8s/mysql.yaml
echo ""

echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n concert-platform --timeout=120s || true
echo ""

echo "📦 Step 6/6: Deploying Backend and Frontend..."
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress.yaml
echo ""

echo "⏳ Waiting for deployments to be ready..."
sleep 5
kubectl rollout status deployment/backend -n concert-platform --timeout=120s || true
kubectl rollout status deployment/frontend -n concert-platform --timeout=120s || true
echo ""

# Show deployment status
echo "📊 Deployment Status:"
echo "===================="
kubectl get all -n concert-platform
echo ""

# Show access information
echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo "📝 Access Information:"
echo "====================="
echo ""
echo "Frontend Service:"
FRONTEND_PORT=$(kubectl get svc frontend-service -n concert-platform -o jsonpath='{.spec.ports[0].nodePort}')
echo "  → http://localhost:${FRONTEND_PORT:-'<pending>'}"
echo ""
echo "Backend Service:"
BACKEND_PORT=$(kubectl get svc backend-service -n concert-platform -o jsonpath='{.spec.ports[0].port}')
echo "  → http://localhost:8080 (via port-forward)"
echo "  → Run: kubectl port-forward -n concert-platform svc/backend-service 8080:8080"
echo ""
echo "View Logs:"
echo "  Backend:  kubectl logs -f -n concert-platform -l app=backend"
echo "  Frontend: kubectl logs -f -n concert-platform -l app=frontend"
echo ""
echo "Check Status:"
echo "  kubectl get pods -n concert-platform"
echo ""
echo "Clean Up:"
echo "  kubectl delete namespace concert-platform"
echo ""
