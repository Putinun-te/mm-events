#!/bin/bash

# K8s Deployment Helper Script
# Usage: ./k8s-deploy-helper.sh [command] [options]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="concert-platform"
DEPLOYMENT_TIMEOUT=300

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    log_success "Namespace created"
}

# Create secrets
create_secrets() {
    log_info "Creating secrets..."
    
    # Check if secret already exists
    if kubectl get secret concert-secrets -n $NAMESPACE &> /dev/null; then
        log_warning "Secret 'concert-secrets' already exists, skipping..."
        return
    fi
    
    read -sp "Enter MySQL password: " DB_PASSWORD
    echo
    
    kubectl create secret generic concert-secrets \
        -n $NAMESPACE \
        --from-literal=SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Secrets created"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure (ConfigMap, MySQL)..."
    
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/mysql.yaml
    
    log_info "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=${DEPLOYMENT_TIMEOUT}s
    
    log_success "Infrastructure deployed"
}

# Deploy applications
deploy_applications() {
    log_info "Deploying backend and frontend..."
    
    kubectl apply -f k8s/backend.yaml
    kubectl apply -f k8s/frontend.yaml
    
    log_info "Waiting for backend rollout..."
    kubectl rollout status deployment/backend -n $NAMESPACE --timeout=${DEPLOYMENT_TIMEOUT}s
    
    log_info "Waiting for frontend rollout..."
    kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=${DEPLOYMENT_TIMEOUT}s
    
    log_success "Applications deployed"
}

# Deploy ingress
deploy_ingress() {
    log_info "Deploying ingress..."
    kubectl apply -f k8s/ingress.yaml
    log_success "Ingress deployed"
}

# Full deployment
deploy_all() {
    log_info "Starting full deployment..."
    
    check_prerequisites
    create_namespace
    create_secrets
    deploy_infrastructure
    deploy_applications
    deploy_ingress
    
    show_status
    
    log_success "Deployment completed!"
}

# Show deployment status
show_status() {
    log_info "Deployment Status:"
    echo ""
    echo "Deployments:"
    kubectl get deployments -n $NAMESPACE
    echo ""
    echo "StatefulSets:"
    kubectl get statefulsets -n $NAMESPACE
    echo ""
    echo "Pods:"
    kubectl get pods -n $NAMESPACE
    echo ""
    echo "Services:"
    kubectl get svc -n $NAMESPACE
    echo ""
    echo "Ingress:"
    kubectl get ingress -n $NAMESPACE
}

# Show logs
show_logs() {
    local component=$1
    
    if [ -z "$component" ]; then
        log_error "Please specify component: backend, frontend, or mysql"
        return 1
    fi
    
    case $component in
        backend)
            kubectl logs -n $NAMESPACE -f deployment/backend
            ;;
        frontend)
            kubectl logs -n $NAMESPACE -f deployment/frontend
            ;;
        mysql)
            kubectl logs -n $NAMESPACE -f statefulset/mysql
            ;;
        *)
            log_error "Unknown component: $component"
            return 1
            ;;
    esac
}

# Scale deployment
scale_deployment() {
    local deployment=$1
    local replicas=$2
    
    if [ -z "$deployment" ] || [ -z "$replicas" ]; then
        log_error "Usage: scale [deployment] [replicas]"
        return 1
    fi
    
    log_info "Scaling $deployment to $replicas replicas..."
    kubectl scale deployment $deployment -n $NAMESPACE --replicas=$replicas
    
    log_info "Waiting for rollout..."
    kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=${DEPLOYMENT_TIMEOUT}s
    
    log_success "Scaling completed"
}

# Rollback deployment
rollback_deployment() {
    local deployment=$1
    
    if [ -z "$deployment" ]; then
        log_error "Usage: rollback [deployment]"
        return 1
    fi
    
    log_info "Rolling back $deployment..."
    kubectl rollout undo deployment/$deployment -n $NAMESPACE
    
    log_info "Waiting for rollout..."
    kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=${DEPLOYMENT_TIMEOUT}s
    
    log_success "Rollback completed"
}

# Cleanup
cleanup() {
    log_warning "Deleting namespace $NAMESPACE..."
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        kubectl delete namespace $NAMESPACE
        log_success "Cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Restart deployment
restart_deployment() {
    local deployment=$1
    
    if [ -z "$deployment" ]; then
        log_error "Usage: restart [deployment]"
        return 1
    fi
    
    log_info "Restarting $deployment..."
    kubectl rollout restart deployment/$deployment -n $NAMESPACE
    
    log_info "Waiting for rollout..."
    kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=${DEPLOYMENT_TIMEOUT}s
    
    log_success "Restart completed"
}

# Main menu
show_usage() {
    cat << EOF
K8s Deployment Helper

Usage: $0 [command] [options]

Commands:
    deploy              Full deployment (all steps)
    status              Show deployment status
    logs [component]    Show logs (backend|frontend|mysql)
    scale [dep] [num]   Scale deployment to N replicas
    restart [dep]       Restart deployment
    rollback [dep]      Rollback deployment to previous version
    cleanup             Delete namespace and all resources
    help                Show this help message

Examples:
    $0 deploy
    $0 status
    $0 logs backend
    $0 scale backend 5
    $0 restart frontend
    $0 rollback backend
    $0 cleanup

EOF
}

# Main
case "${1:-help}" in
    deploy)
        deploy_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    scale)
        scale_deployment "$2" "$3"
        ;;
    restart)
        restart_deployment "$2"
        ;;
    rollback)
        rollback_deployment "$2"
        ;;
    cleanup)
        cleanup
        ;;
    help)
        show_usage
        ;;
    *)
        log_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
