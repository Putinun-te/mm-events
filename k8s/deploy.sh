#!/bin/bash

# deploy.sh - Automated Kubernetes deployment script
# Usage: ./deploy.sh [environment]

set -e

# Configuration
NAMESPACE="concert-platform"
ENVIRONMENT="${1:-production}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

deploy_namespace() {
    log_info "Creating namespace: ${NAMESPACE}..."
    kubectl apply -f k8s/namespace.yaml
    log_success "Namespace created/updated"
}

deploy_configmap() {
    log_info "Applying configurations..."
    kubectl apply -f k8s/configmap.yaml
    log_success "ConfigMap and Secrets applied"
}

deploy_mysql() {
    log_info "Deploying MySQL database..."
    kubectl apply -f k8s/mysql.yaml
    
    log_info "Waiting for MySQL to be ready (timeout: 5 minutes)..."
    if kubectl wait --for=condition=ready pod -l app=mysql -n ${NAMESPACE} --timeout=300s; then
        log_success "MySQL is ready"
    else
        log_warning "MySQL readiness check timed out. Continuing anyway..."
    fi
}

deploy_backend() {
    log_info "Deploying backend service..."
    kubectl apply -f k8s/backend.yaml
    
    log_info "Waiting for backend deployment to be ready (timeout: 5 minutes)..."
    if kubectl rollout status deployment/backend -n ${NAMESPACE} --timeout=300s; then
        log_success "Backend deployed successfully"
    else
        log_error "Backend deployment failed"
        exit 1
    fi
}

deploy_frontend() {
    log_info "Deploying frontend service..."
    kubectl apply -f k8s/frontend.yaml
    
    log_info "Waiting for frontend deployment to be ready (timeout: 3 minutes)..."
    if kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=180s; then
        log_success "Frontend deployed successfully"
    else
        log_error "Frontend deployment failed"
        exit 1
    fi
}

deploy_ingress() {
    log_info "Configuring ingress..."
    kubectl apply -f k8s/ingress.yaml
    log_success "Ingress configured"
}

show_status() {
    echo ""
    log_info "Deployment Status:"
    echo ""
    
    echo "📦 Pods:"
    kubectl get pods -n ${NAMESPACE}
    echo ""
    
    echo "🔌 Services:"
    kubectl get svc -n ${NAMESPACE}
    echo ""
    
    echo "🌐 Ingress:"
    kubectl get ingress -n ${NAMESPACE}
    echo ""
}

show_access_info() {
    echo ""
    log_success "Deployment Complete!"
    echo ""
    
    log_info "Access Information:"
    echo ""
    
    # Frontend URL
    FRONTEND_IP=$(kubectl get svc frontend-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    if [ "$FRONTEND_IP" != "pending" ] && [ -n "$FRONTEND_IP" ]; then
        echo "🎨 Frontend: http://${FRONTEND_IP}"
    else
        echo "🎨 Frontend: LoadBalancer IP pending (check with: kubectl get svc -n ${NAMESPACE})"
    fi
    
    # Backend URL (internal)
    BACKEND_IP=$(kubectl get svc backend-service -n ${NAMESPACE} -o jsonpath='{.spec.clusterIP}')
    echo "☕ Backend (internal): http://${BACKEND_IP}:8080"
    
    # Ingress URL
    INGRESS_HOST=$(kubectl get ingress concert-ingress -n ${NAMESPACE} -o jsonpath='{.spec.rules[0].host}')
    echo "🌐 Ingress: https://${INGRESS_HOST}"
    
    echo ""
    log_info "Useful Commands:"
    echo "  View logs: kubectl logs -f deployment/<service-name> -n ${NAMESPACE}"
    echo "  Scale: kubectl scale deployment/<service-name> --replicas=N -n ${NAMESPACE}"
    echo "  Status: kubectl get all -n ${NAMESPACE}"
    echo ""
}

# Main deployment flow
main() {
    echo ""
    log_info "🚀 MM Concerts Platform - Kubernetes Deployment"
    log_info "Environment: ${ENVIRONMENT}"
    log_info "Namespace: ${NAMESPACE}"
    echo ""
    
    check_prerequisites
    deploy_namespace
    deploy_configmap
    deploy_mysql
    deploy_backend
    deploy_frontend
    deploy_ingress
    show_status
    show_access_info
}

# Run main function
main
