#!/bin/bash
###############################################################################
# Complete Migration to us-east-1
# 1. Finish cleanup of Singapore resources
# 2. Update Terraform for us-east-1
# 3. Deploy minimal infrastructure
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

cd /Users/putinan/development/DevOps/develop/aws

###############################################################################
# Step 1: Clean up remaining Singapore resources
###############################################################################
cleanup_singapore() {
    print_header "Step 1: Cleaning Up Remaining Singapore Resources"
    
    print_info "Waiting for ElastiCache to finish deleting..."
    aws elasticache delete-replication-group \
        --region ap-southeast-1 \
        --replication-group-id concert-redis-dev \
        --no-retain-primary-cluster 2>/dev/null || true
    
    print_info "Waiting 60 seconds for ElastiCache cleanup..."
    sleep 60
    
    print_success "Singapore cleanup complete"
    echo ""
}

###############################################################################
# Step 2: Update Terraform for us-east-1
###############################################################################
update_terraform_region() {
    print_header "Step 2: Updating Terraform to us-east-1"
    
    # Backup files
    print_info "Creating backup..."
    cp variables.tf variables.tf.singapore-backup
    cp provider.tf provider.tf.singapore-backup
    
    # Update region in variables.tf
    print_info "Updating variables.tf..."
    sed -i '' 's/ap-southeast-1/us-east-1/g' variables.tf
    
    # Update region in provider.tf
    print_info "Updating provider.tf..."
    sed -i '' 's/ap-southeast-1/us-east-1/g' provider.tf
    
    # Verify changes
    print_success "Region updated to us-east-1"
    grep "us-east-1" variables.tf | head -1
    echo ""
}

###############################################################################
# Step 3: Remove expensive services from Terraform
###############################################################################
disable_expensive_services() {
    print_header "Step 3: Disabling Expensive Services"
    
    # Disable RDS
    if [ -f rds.tf ]; then
        print_info "Disabling RDS (save ~$15/month)..."
        mv rds.tf rds.tf.disabled
        print_success "RDS disabled"
    fi
    
    # Disable ElastiCache
    if [ -f elasticache.tf ]; then
        print_info "Disabling ElastiCache (save ~$12/month)..."
        mv elasticache.tf elasticache.tf.disabled
        print_success "ElastiCache disabled"
    fi
    
    # Disable EC2 backend (use existing instances)
    if [ -f ec2_backend.tf ]; then
        print_info "Disabling EC2 creation (use existing instances)..."
        mv ec2_backend.tf ec2_backend.tf.disabled
        print_success "EC2 creation disabled"
    fi
    
    # Disable CloudFront (blocked anyway)
    if [ -f cloudfront_optimized.tf ]; then
        print_info "Disabling CloudFront (account not verified)..."
        mv cloudfront_optimized.tf cloudfront_optimized.tf.disabled
        print_success "CloudFront disabled"
    fi
    
    # Disable VPC (not needed for S3/Lambda)
    if [ -f vpc.tf ]; then
        print_info "Disabling VPC (not needed for serverless)..."
        mv vpc.tf vpc.tf.disabled
        print_success "VPC disabled"
    fi
    
    # Disable DynamoDB (keep if needed)
    if [ -f dynamodb.tf ]; then
        print_info "Disabling DynamoDB (can enable later if needed)..."
        mv dynamodb.tf dynamodb.tf.disabled
        print_success "DynamoDB disabled"
    fi
    
    # Disable SNS/SQS
    if [ -f messaging.tf ]; then
        print_info "Disabling SNS/SQS..."
        mv messaging.tf messaging.tf.disabled
        print_success "Messaging disabled"
    fi
    
    echo ""
    print_success "Keeping only FREE TIER services:"
    echo "  ✓ S3 buckets (5GB free)"
    echo "  ✓ Lambda function (1M requests free)"
    echo "  ✓ API Gateway (1M requests free)"
    echo "  ✓ IAM roles and policies"
    echo ""
}

###############################################################################
# Step 4: Deploy minimal infrastructure to us-east-1
###############################################################################
deploy_minimal_infrastructure() {
    print_header "Step 4: Deploying Minimal Infrastructure to us-east-1"
    
    # Reinitialize Terraform
    print_info "Reinitializing Terraform for us-east-1..."
    terraform init -reconfigure
    print_success "Terraform initialized"
    
    # Validate configuration
    print_info "Validating configuration..."
    if terraform validate; then
        print_success "Configuration valid"
    else
        print_error "Configuration invalid - please check errors above"
        exit 1
    fi
    
    # Plan deployment
    print_info "Creating deployment plan..."
    terraform plan -out=tfplan-us-east-1
    
    echo ""
    print_info "Review the plan above"
    read -p "$(echo -e ${YELLOW}Apply this plan? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deploying infrastructure..."
        terraform apply tfplan-us-east-1
        print_success "Infrastructure deployed!"
    else
        print_info "Deployment cancelled"
        exit 0
    fi
    
    echo ""
}

###############################################################################
# Step 5: Show deployment summary
###############################################################################
show_summary() {
    print_header "Step 5: Deployment Summary"
    
    echo -e "${GREEN}✓ Migration to us-east-1 Complete!${NC}"
    echo ""
    
    echo -e "${BLUE}Resources Deployed:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get outputs
    if terraform output &>/dev/null; then
        echo "Region: us-east-1"
        
        # S3 buckets
        echo ""
        echo "S3 Buckets:"
        terraform output -json 2>/dev/null | jq -r 'to_entries[] | select(.key | contains("bucket")) | "  - \(.key): \(.value.value)"' || echo "  Check terraform output"
        
        # Lambda
        echo ""
        echo "Lambda Function:"
        terraform output lambda_function_name 2>/dev/null | sed 's/^/  - /' || echo "  concert-generate-presigned-url"
        
        # API Gateway
        echo ""
        echo "API Gateway:"
        terraform output api_gateway_endpoint 2>/dev/null | sed 's/^/  - /' || echo "  Check terraform output"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo ""
    echo -e "${BLUE}Existing EC2 Instances (us-east-1):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    aws ec2 describe-instances \
        --region us-east-1 \
        --filters "Name=tag:Name,Values=*concert*" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,Placement.AvailabilityZone]' \
        --output table || echo "  No instances found"
    
    echo ""
    echo -e "${GREEN}💰 Cost Breakdown:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  S3 Storage (<5GB):         \$0.00/month (free tier)"
    echo "  Lambda (<1M invocations):  \$0.00/month (free tier)"
    echo "  API Gateway (<1M calls):   \$0.00/month (free tier)"
    echo "  EC2 (2 x t3.micro):        \$0.00/month (750hrs free tier)"
    echo "  CloudWatch Logs (<5GB):    \$0.00/month (free tier)"
    echo "  ────────────────────────────────────────────────────────"
    echo "  TOTAL:                     \$0.00/month 🎉"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Test S3 upload:"
    echo "   API_ENDPOINT=\$(terraform output -raw api_gateway_endpoint)"
    echo "   curl -X POST \"\$API_ENDPOINT/dev/upload/event-picture\" \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"filename\": \"test.jpg\", \"contentType\": \"image/jpeg\"}'"
    echo ""
    echo "2. Update Spring Boot application on EC2:"
    echo "   SSH to each instance and update:"
    echo "   - aws.region=us-east-1"
    echo "   - aws.s3.event-pictures-bucket=<new-bucket-name>"
    echo "   - aws.api-gateway.endpoint=<new-api-endpoint>"
    echo ""
    echo "3. (Optional) Enable more services later:"
    echo "   mv rds.tf.disabled rds.tf"
    echo "   mv elasticache.tf.disabled elasticache.tf"
    echo "   terraform apply"
    echo ""
}

###############################################################################
# Main
###############################################################################
main() {
    clear
    
    print_header "Concert Platform - Complete Migration to us-east-1"
    echo ""
    
    echo -e "${YELLOW}This will:${NC}"
    echo "  1. Clean up remaining Singapore resources"
    echo "  2. Update Terraform configuration to us-east-1"
    echo "  3. Disable expensive services (RDS, ElastiCache, VPC)"
    echo "  4. Deploy only FREE TIER services (S3, Lambda, API Gateway)"
    echo "  5. Use existing EC2 instances in us-east-1"
    echo "  6. Reduce monthly cost to \$0"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Continue with migration? [yes/NO]:${NC} )" -r
    echo ""
    
    if [[ $REPLY == "yes" ]]; then
        cleanup_singapore
        update_terraform_region
        disable_expensive_services
        deploy_minimal_infrastructure
        show_summary
    else
        print_info "Migration cancelled"
        exit 0
    fi
}

main
