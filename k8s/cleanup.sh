#!/bin/bash

# cleanup.sh - Remove all Kubernetes resources for MM Concerts Platform
# Usage: ./cleanup.sh [--force]

set -e

# Configuration
NAMESPACE="concert-platform"

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

show_resources() {
    log_info "Current resources in namespace ${NAMESPACE}:"
    echo ""
    kubectl get all -n ${NAMESPACE} 2>/dev/null || log_warning "Namespace not found or no resources"
    echo ""
}

confirm_deletion() {
    if [ "$1" != "--force" ]; then
        echo ""
        log_warning "This will delete ALL resources in namespace: ${NAMESPACE}"
        read -p "Are you sure? (yes/no): " -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Cleanup cancelled"
            exit 0
        fi
    fi
}

cleanup_resources() {
    log_info "Deleting resources..."
    
    # Delete in reverse order of dependencies
    log_info "Deleting ingress..."
    kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
    
    log_info "Deleting frontend..."
    kubectl delete -f k8s/frontend.yaml --ignore-not-found=true
    
    log_info "Deleting backend..."
    kubectl delete -f k8s/backend.yaml --ignore-not-found=true
    
    log_info "Deleting MySQL..."
    kubectl delete -f k8s/mysql.yaml --ignore-not-found=true
    
    log_info "Deleting configurations..."
    kubectl delete -f k8s/configmap.yaml --ignore-not-found=true
    
    log_info "Deleting namespace..."
    kubectl delete -f k8s/namespace.yaml --ignore-not-found=true
    
    log_success "All resources deleted"
}

verify_cleanup() {
    log_info "Verifying cleanup..."
    
    # Check if namespace still exists
    if kubectl get namespace ${NAMESPACE} &> /dev/null; then
        log_warning "Namespace still exists (may be in terminating state)"
        log_info "Waiting for namespace deletion..."
        
        # Wait up to 60 seconds for namespace deletion
        for i in {1..60}; do
            if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
                break
            fi
            sleep 1
        done
        
        if kubectl get namespace ${NAMESPACE} &> /dev/null; then
            log_warning "Namespace deletion taking longer than expected"
            log_info "You can check status with: kubectl get namespace ${NAMESPACE}"
        else
            log_success "Namespace fully deleted"
        fi
    else
        log_success "Cleanup verified - namespace removed"
    fi
}

# Main cleanup flow
main() {
    echo ""
    log_info "🧹 MM Concerts Platform - Kubernetes Cleanup"
    log_info "Namespace: ${NAMESPACE}"
    echo ""
    
    show_resources
    confirm_deletion "$1"
    cleanup_resources
    verify_cleanup
    
    echo ""
    log_success "Cleanup completed!"
    echo ""
}

# Run main function
main "$1"
