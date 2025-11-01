#!/bin/bash
###############################################################################
# Force Cleanup Singapore Resources
# Handles dependency issues during terraform destroy
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

REGION="ap-southeast-1"

echo "Cleaning up remaining Singapore resources..."
echo ""

# 1. Remove IAM group memberships
print_info "Removing IAM group memberships..."
aws iam remove-user-from-group --group-name concert-developers --user-name concert-developer-template 2>/dev/null || true
aws iam remove-user-from-group --group-name concert-admins --user-name concert-developer-template 2>/dev/null || true
aws iam remove-user-from-group --group-name concert-testers --user-name concert-developer-template 2>/dev/null || true
aws iam remove-user-from-group --group-name concert-deployment --user-name concert-developer-template 2>/dev/null || true
print_success "IAM memberships removed"

# 2. Delete IAM group policies
print_info "Deleting IAM group inline policies..."
for group in concert-developers concert-admins concert-testers concert-deployment; do
    policies=$(aws iam list-group-policies --group-name $group --query 'PolicyNames[]' --output text 2>/dev/null || echo "")
    for policy in $policies; do
        aws iam delete-group-policy --group-name $group --policy-name $policy 2>/dev/null && echo "  Deleted $group/$policy" || true
    done
done
print_success "IAM group policies deleted"

# 3. Force delete ElastiCache
print_info "Force deleting ElastiCache..."
aws elasticache delete-replication-group \
    --region $REGION \
    --replication-group-id concert-redis-dev \
    --no-retain-primary-cluster 2>/dev/null || true
print_success "ElastiCache deletion initiated"

# 4. Delete SQS queue policies first
print_info "Removing SQS queue policies..."
for queue in concert-email-queue-dev concert-notification-queue-dev concert-analytics-queue-dev concert-refund-queue-dev; do
    QUEUE_URL="https://sqs.$REGION.amazonaws.com/123456789012/$queue"
    aws sqs set-queue-attributes \
        --region $REGION \
        --queue-url $QUEUE_URL \
        --attributes Policy="" 2>/dev/null && echo "  Removed policy from $queue" || true
    
    aws sqs set-queue-attributes \
        --region $REGION \
        --queue-url $QUEUE_URL \
        --attributes RedrivePolicy="" 2>/dev/null && echo "  Removed redrive policy from $queue" || true
done
print_success "SQS policies removed"

# 5. Wait and retry terraform destroy
print_info "Waiting 30 seconds for resources to clean up..."
sleep 30

cd /Users/putinan/development/DevOps/develop/aws

print_info "Running terraform destroy again..."
terraform destroy -auto-approve

print_success "Cleanup complete!"
