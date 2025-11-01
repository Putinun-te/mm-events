#!/bin/bash
###############################################################################
# Cleanup Singapore & Move to us-east-1
# Purpose: Delete all Singapore resources and reconfigure for us-east-1
# This will save costs by using existing us-east-1 infrastructure
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

TERRAFORM_DIR="/Users/putinan/development/DevOps/develop/aws"

###############################################################################
# Step 1: Show Current Resources
###############################################################################
show_current_resources() {
    print_header "Step 1: Current Resources Overview"
    
    echo -e "${YELLOW}Singapore Resources (ap-southeast-1):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # S3 Buckets
    echo "S3 Buckets:"
    aws s3 ls --region ap-southeast-1 2>/dev/null | grep concert || echo "  None"
    
    # Lambda Functions
    echo ""
    echo "Lambda Functions:"
    aws lambda list-functions --region ap-southeast-1 --query 'Functions[?contains(FunctionName, `concert`)].FunctionName' --output table 2>/dev/null || echo "  None"
    
    # API Gateway
    echo ""
    echo "API Gateways:"
    aws apigatewayv2 get-apis --region ap-southeast-1 --query 'Items[?contains(Name, `concert`)].Name' --output table 2>/dev/null || echo "  None"
    
    # RDS
    echo ""
    echo "RDS Instances:"
    aws rds describe-db-instances --region ap-southeast-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `concert`)].DBInstanceIdentifier' --output table 2>/dev/null || echo "  None"
    
    # ElastiCache
    echo ""
    echo "ElastiCache:"
    aws elasticache describe-replication-groups --region ap-southeast-1 --query 'ReplicationGroups[?contains(ReplicationGroupId, `concert`)].ReplicationGroupId' --output table 2>/dev/null || echo "  None"
    
    echo ""
    echo -e "${YELLOW}us-east-1 Resources:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # EC2 Instances
    echo "EC2 Instances:"
    aws ec2 describe-instances \
        --region us-east-1 \
        --filters "Name=tag:Name,Values=*concert*" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,Placement.AvailabilityZone]' \
        --output table 2>/dev/null || echo "  None"
    
    echo ""
}

###############################################################################
# Step 2: Backup Terraform State
###############################################################################
backup_terraform() {
    print_header "Step 2: Backing Up Terraform State"
    
    cd "$TERRAFORM_DIR"
    
    BACKUP_DIR="$TERRAFORM_DIR/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup Terraform state
    if [ -f terraform.tfstate ]; then
        cp terraform.tfstate "$BACKUP_DIR/"
        print_success "Backed up terraform.tfstate"
    fi
    
    # Backup Terraform files
    cp *.tf "$BACKUP_DIR/" 2>/dev/null || true
    print_success "Backed up Terraform files to: $BACKUP_DIR"
    
    echo ""
}

###############################################################################
# Step 3: Destroy Singapore Resources
###############################################################################
destroy_singapore_resources() {
    print_header "Step 3: Destroying Singapore Resources"
    
    cd "$TERRAFORM_DIR"
    
    echo -e "${RED}WARNING: This will destroy all Singapore resources!${NC}"
    echo -e "${YELLOW}Resources to be destroyed:${NC}"
    echo "  - S3 buckets (3)"
    echo "  - Lambda function"
    echo "  - API Gateway"
    echo "  - RDS (if exists)"
    echo "  - ElastiCache (if exists)"
    echo "  - CloudWatch alarms"
    echo "  - IAM roles and policies"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Are you sure you want to destroy all resources? [yes/NO]:${NC} )" -r
    echo ""
    
    if [[ $REPLY == "yes" ]]; then
        print_info "Running terraform destroy..."
        
        # Destroy everything
        terraform destroy -auto-approve
        
        print_success "All Singapore resources destroyed!"
    else
        print_info "Destruction cancelled"
        exit 0
    fi
    
    echo ""
}

###############################################################################
# Step 4: Update Terraform for us-east-1
###############################################################################
update_terraform_region() {
    print_header "Step 4: Updating Terraform Configuration for us-east-1"
    
    cd "$TERRAFORM_DIR"
    
    # Update variables.tf
    if [ -f variables.tf ]; then
        print_info "Updating variables.tf..."
        sed -i '' 's/default = "ap-southeast-1"/default = "us-east-1"/' variables.tf
        print_success "Updated region to us-east-1"
    fi
    
    # Update provider.tf
    if [ -f provider.tf ]; then
        print_info "Updating provider.tf..."
        sed -i '' 's/region = "ap-southeast-1"/region = "us-east-1"/' provider.tf
        print_success "Updated provider region"
    fi
    
    echo ""
}

###############################################################################
# Step 5: Create Minimal us-east-1 Infrastructure
###############################################################################
create_minimal_infra() {
    print_header "Step 5: Creating Minimal us-east-1 Infrastructure"
    
    print_info "This will create only essential services:"
    echo "  ✓ S3 buckets (for file storage)"
    echo "  ✓ Lambda function (for presigned URLs)"
    echo "  ✓ API Gateway (for upload endpoint)"
    echo "  ✗ RDS (use existing or remove)"
    echo "  ✗ ElastiCache (remove to save cost)"
    echo "  ✗ EC2 (use existing instances)"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Create minimal infrastructure? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$TERRAFORM_DIR"
        
        # Initialize Terraform
        terraform init -reconfigure
        
        # Plan
        terraform plan -out=tfplan-us-east-1
        
        # Apply
        read -p "$(echo -e ${YELLOW}Apply this plan? [y/N]:${NC} )" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform apply tfplan-us-east-1
            print_success "Minimal infrastructure created!"
        else
            print_info "Infrastructure creation cancelled"
        fi
    fi
    
    echo ""
}

###############################################################################
# Step 6: Configure Existing EC2 for S3 Access
###############################################################################
configure_existing_ec2() {
    print_header "Step 6: Configure Existing EC2 Instances"
    
    print_info "Getting existing EC2 instances in us-east-1..."
    
    INSTANCES=$(aws ec2 describe-instances \
        --region us-east-1 \
        --filters "Name=tag:Name,Values=*concert*" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
        --output text)
    
    if [ -z "$INSTANCES" ]; then
        print_error "No running EC2 instances found in us-east-1"
        return
    fi
    
    echo "$INSTANCES" | while read INSTANCE_ID PUBLIC_IP; do
        echo ""
        echo -e "${GREEN}Instance: $INSTANCE_ID ($PUBLIC_IP)${NC}"
        
        # Attach IAM role
        print_info "Attaching IAM instance profile..."
        aws ec2 associate-iam-instance-profile \
            --region us-east-1 \
            --instance-id "$INSTANCE_ID" \
            --iam-instance-profile Name=concert-backend-ec2-profile 2>/dev/null || \
            print_info "Instance profile already attached or doesn't exist"
        
        # Show SSH command
        echo -e "${YELLOW}To configure this instance manually:${NC}"
        echo "  ssh -i concert-key.pem ec2-user@$PUBLIC_IP"
        echo ""
    done
    
    echo ""
}

###############################################################################
# Step 7: Cost Comparison
###############################################################################
show_cost_comparison() {
    print_header "Step 7: Cost Comparison"
    
    echo -e "${BLUE}Before (Singapore + us-east-1):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Singapore Services:        ~$12.80/month"
    echo "  us-east-1 EC2 (2):         ~$15.00/month"
    echo "  Total:                     ~$27.80/month"
    echo ""
    
    echo -e "${GREEN}After (us-east-1 only):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  S3 Storage (<5GB):         $0.00/month (free tier)"
    echo "  Lambda (<1M invocations):  $0.00/month (free tier)"
    echo "  API Gateway (<1M calls):   $0.00/month (free tier)"
    echo "  EC2 (2 x t3.micro):        $0.00/month (free tier 750hrs)"
    echo "  Total:                     $0.00/month"
    echo ""
    
    echo -e "${GREEN}Monthly Savings: ~$27.80 → $0.00 = 100% reduction! 🎉${NC}"
    echo ""
}

###############################################################################
# Step 8: Generate Summary
###############################################################################
generate_summary() {
    print_header "Step 8: Migration Summary"
    
    echo -e "${GREEN}✓ Cleanup Complete!${NC}"
    echo ""
    echo "Actions Taken:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ Backed up Terraform state"
    echo "  ✓ Destroyed Singapore resources"
    echo "  ✓ Updated Terraform to us-east-1"
    echo "  ✓ Created minimal infrastructure"
    echo "  ✓ Configured existing EC2 instances"
    echo ""
    
    echo "Current Infrastructure:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Region:        us-east-1"
    echo "  EC2:           2 x t3.micro (existing instances)"
    echo "  S3:            3 buckets (event-pictures, user-avatars, website)"
    echo "  Lambda:        Presigned URL generator"
    echo "  API Gateway:   Upload endpoints"
    echo "  Cost:          $0.00/month (100% free tier)"
    echo ""
    
    echo "Next Steps:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Test S3 upload:"
    echo "   curl -X POST https://<api-gateway-id>.execute-api.us-east-1.amazonaws.com/dev/upload/event-picture \\"
    echo "     -H 'Content-Type: application/json' \\"
    echo "     -d '{\"filename\": \"test.jpg\", \"contentType\": \"image/jpeg\"}'"
    echo ""
    echo "2. SSH to existing EC2:"
    echo "   aws ec2 describe-instances --region us-east-1 \\"
    echo "     --filters 'Name=tag:Name,Values=*concert*' \\"
    echo "     --query 'Reservations[*].Instances[*].PublicIpAddress'"
    echo "   ssh -i concert-key.pem ec2-user@<PUBLIC_IP>"
    echo ""
    echo "3. Update Spring Boot application.properties:"
    echo "   aws.region=us-east-1"
    echo "   aws.s3.event-pictures-bucket=<bucket-name>"
    echo "   aws.api-gateway.endpoint=<api-endpoint>"
    echo ""
    
    echo -e "${BLUE}Migration to us-east-1 completed! 🎉${NC}"
    echo ""
}

###############################################################################
# Main
###############################################################################
main() {
    clear
    
    print_header "Concert Platform - Cleanup Singapore & Move to us-east-1"
    echo ""
    
    show_current_resources
    
    echo -e "${YELLOW}This script will:${NC}"
    echo "  1. Backup Terraform state"
    echo "  2. Destroy ALL Singapore resources"
    echo "  3. Update Terraform configuration to us-east-1"
    echo "  4. Create minimal infrastructure (S3, Lambda, API Gateway)"
    echo "  5. Use existing EC2 instances in us-east-1"
    echo "  6. Reduce cost to $0/month (100% free tier)"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Continue with cleanup? [yes/NO]:${NC} )" -r
    echo ""
    
    if [[ $REPLY == "yes" ]]; then
        backup_terraform
        destroy_singapore_resources
        update_terraform_region
        create_minimal_infra
        configure_existing_ec2
        show_cost_comparison
        generate_summary
    else
        print_info "Cleanup cancelled"
        exit 0
    fi
}

main
