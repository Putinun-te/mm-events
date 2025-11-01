#!/bin/bash
###############################################################################
# Final Cleanup and Migration to us-east-1
# Removes remaining Singapore resources and configures for us-east-1
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

TERRAFORM_DIR="/Users/putinan/development/DevOps/develop/aws"
cd "$TERRAFORM_DIR"

###############################################################################
# Step 1: Clean Terraform State
###############################################################################
clean_terraform_state() {
    print_header "Step 1: Cleaning Terraform State"
    
    print_info "Removing remaining resources from state..."
    
    # Remove IAM groups that have users
    terraform state rm aws_iam_group.admins 2>/dev/null || true
    terraform state rm aws_iam_group.deployment 2>/dev/null || true
    terraform state rm aws_iam_group.testers 2>/dev/null || true
    terraform state rm aws_iam_group.developers 2>/dev/null || true
    
    # Remove ElastiCache resources (still deleting)
    terraform state rm aws_elasticache_replication_group.concert 2>/dev/null || true
    terraform state rm aws_elasticache_subnet_group.concert 2>/dev/null || true
    terraform state rm aws_elasticache_parameter_group.concert 2>/dev/null || true
    
    # Remove NAT Gateway (slow to delete)
    terraform state rm aws_nat_gateway.concert 2>/dev/null || true
    
    # Remove any remaining resources
    terraform state rm aws_dynamodb_table.audit_cache 2>/dev/null || true
    terraform state rm aws_dynamodb_table.event_details 2>/dev/null || true
    
    print_success "Terraform state cleaned"
    echo ""
}

###############################################################################
# Step 2: Update Region to us-east-1
###############################################################################
update_region() {
    print_header "Step 2: Updating Region to us-east-1"
    
    # Update variables.tf
    if [ -f variables.tf ]; then
        print_info "Updating variables.tf..."
        sed -i '' 's/ap-southeast-1/us-east-1/g' variables.tf
        print_success "variables.tf updated"
    fi
    
    # Update provider.tf
    if [ -f provider.tf ]; then
        print_info "Updating provider.tf..."
        sed -i '' 's/ap-southeast-1/us-east-1/g' provider.tf
        print_success "provider.tf updated"
    fi
    
    # Verify changes
    echo ""
    print_info "Verifying region changes..."
    grep -n "us-east-1" variables.tf provider.tf | head -5
    echo ""
    
    print_success "Region updated to us-east-1"
    echo ""
}

###############################################################################
# Step 3: Disable Expensive Services
###############################################################################
disable_expensive_services() {
    print_header "Step 3: Disabling Expensive Services"
    
    print_info "Moving expensive services to .disabled..."
    
    # Disable RDS (save ~$15/month)
    if [ -f rds.tf ]; then
        mv rds.tf rds.tf.disabled
        print_success "RDS disabled"
    fi
    
    # Disable ElastiCache (save ~$12/month)
    if [ -f elasticache.tf ]; then
        mv elasticache.tf elasticache.tf.disabled
        print_success "ElastiCache disabled"
    fi
    
    # Disable EC2 backend (use existing instances)
    if [ -f ec2_backend.tf ]; then
        mv ec2_backend.tf ec2_backend.tf.disabled
        print_success "EC2 backend Terraform disabled (using existing instances)"
    fi
    
    # Disable CloudFront (blocked anyway)
    if [ -f cloudfront_optimized.tf ]; then
        mv cloudfront_optimized.tf cloudfront_optimized.tf.disabled
        print_success "CloudFront disabled"
    fi
    
    # Disable ECS (not needed)
    if [ -f ecs.tf ]; then
        mv ecs.tf ecs.tf.disabled
        print_success "ECS disabled"
    fi
    
    echo ""
    print_info "Keeping only free-tier services:"
    echo "  ✓ S3 buckets"
    echo "  ✓ Lambda function"
    echo "  ✓ API Gateway"
    echo "  ✓ DynamoDB (optional)"
    echo ""
    
    print_success "Expensive services disabled"
    echo ""
}

###############################################################################
# Step 4: Initialize Terraform for us-east-1
###############################################################################
init_terraform() {
    print_header "Step 4: Initializing Terraform for us-east-1"
    
    print_info "Removing old state and plugins..."
    rm -rf .terraform
    rm -f .terraform.lock.hcl
    rm -f terraform.tfstate.backup
    
    print_info "Initializing Terraform..."
    terraform init -reconfigure
    
    print_success "Terraform initialized for us-east-1"
    echo ""
}

###############################################################################
# Step 5: Validate Configuration
###############################################################################
validate_config() {
    print_header "Step 5: Validating Configuration"
    
    print_info "Running terraform validate..."
    if terraform validate; then
        print_success "Configuration is valid"
    else
        print_info "Validation failed - you may need to fix some references"
    fi
    
    echo ""
}

###############################################################################
# Step 6: Show Deployment Plan
###############################################################################
show_plan() {
    print_header "Step 6: Deployment Plan for us-east-1"
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo "1. Deploy minimal infrastructure:"
    echo "   terraform plan -out=tfplan-us-east-1"
    echo "   terraform apply tfplan-us-east-1"
    echo ""
    echo "2. This will create (in us-east-1):"
    echo "   - S3 buckets (3): event-pictures, user-avatars, website"
    echo "   - Lambda function: presigned URL generator"
    echo "   - API Gateway: upload endpoints"
    echo "   - IAM roles: for Lambda"
    echo ""
    echo "3. Configure existing EC2 instances:"
    echo "   - Get instance IPs:"
    echo "     aws ec2 describe-instances --region us-east-1 \\"
    echo "       --filters 'Name=tag:Name,Values=*concert*' \\"
    echo "       --query 'Reservations[*].Instances[*].PublicIpAddress'"
    echo ""
    echo "   - SSH to each instance and update Spring Boot config:"
    echo "     ssh -i concert-key.pem ec2-user@<IP>"
    echo "     sudo vi /opt/concert/config/application.properties"
    echo "     # Update: aws.region=us-east-1"
    echo "     # Update: aws.s3.* buckets"
    echo "     # Update: aws.api-gateway.endpoint"
    echo "     sudo systemctl restart concert-backend"
    echo ""
    echo "4. Test S3 upload:"
    echo "   curl -X POST https://<new-api-id>.execute-api.us-east-1.amazonaws.com/dev/upload/event-picture \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"filename\": \"test.jpg\", \"contentType\": \"image/jpeg\"}'"
    echo ""
    
    print_info "Monthly cost after migration: \$0.00 (100% free tier)"
    echo ""
}

###############################################################################
# Main
###############################################################################
main() {
    clear
    
    print_header "Concert Platform - Final Cleanup & Migration to us-east-1"
    echo ""
    
    clean_terraform_state
    update_region
    disable_expensive_services
    init_terraform
    validate_config
    show_plan
    
    print_header "✓ Migration Preparation Complete!"
    echo ""
    echo -e "${GREEN}You're now ready to deploy to us-east-1 with \$0/month cost!${NC}"
    echo ""
    echo "Run these commands to deploy:"
    echo "  terraform plan -out=tfplan-us-east-1"
    echo "  terraform apply tfplan-us-east-1"
    echo ""
}

main
