#!/bin/bash

# rollback.sh - Rollback Kubernetes deployments
# Usage: ./rollback.sh [backend|frontend|all] [revision]

set -e

# Configuration
NAMESPACE="concert-platform"
SERVICE="${1:-all}"
REVISION="${2}"

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

show_history() {
    local deployment=$1
    log_info "Rollout history for ${deployment}:"
    kubectl rollout history deployment/${deployment} -n ${NAMESPACE}
    echo ""
}

rollback_deployment() {
    local deployment=$1
    
    log_info "Rolling back ${deployment}..."
    
    if [ -n "$REVISION" ]; then
        log_info "Rolling back to revision ${REVISION}..."
        kubectl rollout undo deployment/${deployment} --to-revision=${REVISION} -n ${NAMESPACE}
    else
        log_info "Rolling back to previous version..."
        kubectl rollout undo deployment/${deployment} -n ${NAMESPACE}
    fi
    
    log_info "Waiting for rollback to complete..."
    if kubectl rollout status deployment/${deployment} -n ${NAMESPACE} --timeout=300s; then
        log_success "${deployment} rolled back successfully"
    else
        log_error "${deployment} rollback failed"
        exit 1
    fi
}

show_current_status() {
    log_info "Current deployment status:"
    echo ""
    kubectl get pods -n ${NAMESPACE}
    echo ""
}

# Main rollback flow
main() {
    echo ""
    log_info "🔄 MM Concerts Platform - Rollback"
    log_info "Namespace: ${NAMESPACE}"
    log_info "Service: ${SERVICE}"
    echo ""
    
    case $SERVICE in
        backend)
            show_history "backend"
            read -p "Proceed with rollback? (yes/no): " -r
            if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                rollback_deployment "backend"
            else
                log_info "Rollback cancelled"
                exit 0
            fi
            ;;
        frontend)
            show_history "frontend"
            read -p "Proceed with rollback? (yes/no): " -r
            if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                rollback_deployment "frontend"
            else
                log_info "Rollback cancelled"
                exit 0
            fi
            ;;
        all)
            show_history "backend"
            show_history "frontend"
            read -p "Proceed with rollback of both services? (yes/no): " -r
            if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                rollback_deployment "backend"
                rollback_deployment "frontend"
            else
                log_info "Rollback cancelled"
                exit 0
            fi
            ;;
        *)
            log_error "Invalid service: ${SERVICE}"
            log_info "Usage: ./rollback.sh [backend|frontend|all] [revision]"
            exit 1
            ;;
    esac
    
    show_current_status
    
    echo ""
    log_success "Rollback completed!"
    echo ""
}

# Run main function
main
