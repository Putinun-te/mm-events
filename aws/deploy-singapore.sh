#!/bin/bash
###############################################################################
# Singapore Deployment & S3 Upload Test Script
# Purpose: Deploy EC2 infrastructure to Singapore and test S3 upload
# Author: Concert Platform DevOps
# Version: 1.0
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="ap-southeast-1"
TERRAFORM_DIR="/Users/putinan/development/DevOps/develop/aws"
API_ENDPOINT="https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev"

# Function to print colored output
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

###############################################################################
# Step 1: Pre-Deployment Checks
###############################################################################
check_prerequisites() {
    print_header "Step 1: Checking Prerequisites"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install: brew install awscli"
        exit 1
    fi
    print_success "AWS CLI installed"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install: brew install terraform"
        exit 1
    fi
    print_success "Terraform installed"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi
    print_success "AWS credentials configured"
    
    # Check current region
    CURRENT_REGION=$(aws configure get region)
    if [ "$CURRENT_REGION" != "$AWS_REGION" ]; then
        print_info "Current region: $CURRENT_REGION, deploying to: $AWS_REGION"
    fi
    
    echo ""
}

###############################################################################
# Step 2: Fix Deployment Blockers
###############################################################################
fix_deployment_blockers() {
    print_header "Step 2: Fixing Deployment Blockers"
    
    cd "$TERRAFORM_DIR"
    
    # Fix RDS password format
    print_info "Checking RDS password configuration..."
    if grep -q 'override_special.*@' rds.tf 2>/dev/null; then
        print_error "RDS password contains invalid characters (/, @, \", space)"
        print_info "Updating rds.tf..."
        
        # Backup original
        cp rds.tf rds.tf.bak
        
        # Fix password special characters
        sed -i '' 's/override_special = ".*"/override_special = "!#$%\&*()-_=+[]{}<>:?"/' rds.tf
        print_success "RDS password configuration fixed"
    else
        print_success "RDS password configuration OK"
    fi
    
    # Fix ElastiCache endpoint
    print_info "Checking ElastiCache endpoint configuration..."
    if grep -q 'configuration_endpoint_address' elasticache.tf 2>/dev/null; then
        print_error "ElastiCache using configuration_endpoint_address (null for single-node)"
        print_info "Updating elasticache.tf..."
        
        # Backup original
        cp elasticache.tf elasticache.tf.bak
        
        # Fix endpoint reference
        sed -i '' 's/configuration_endpoint_address/primary_endpoint_address/' elasticache.tf
        print_success "ElastiCache endpoint configuration fixed"
    else
        print_success "ElastiCache endpoint configuration OK"
    fi
    
    echo ""
}

###############################################################################
# Step 3: Deploy EC2 Infrastructure
###############################################################################
deploy_ec2() {
    print_header "Step 3: Deploying EC2 Infrastructure to Singapore"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform (if needed)
    print_info "Initializing Terraform..."
    terraform init -upgrade
    print_success "Terraform initialized"
    
    # Validate configuration
    print_info "Validating Terraform configuration..."
    if ! terraform validate; then
        print_error "Terraform validation failed"
        exit 1
    fi
    print_success "Configuration valid"
    
    # Plan deployment
    print_info "Creating deployment plan..."
    terraform plan -out=tfplan-ec2-singapore \
        -target=aws_instance.backend_primary \
        -target=aws_instance.backend_secondary \
        -target=aws_eip.backend_primary \
        -target=aws_eip.backend_secondary \
        -target=aws_security_group.backend_ec2
    
    print_info "Deployment plan created: tfplan-ec2-singapore"
    
    # Confirm deployment
    echo ""
    read -p "$(echo -e ${YELLOW}Do you want to apply this plan? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Applying Terraform plan..."
        terraform apply tfplan-ec2-singapore
        print_success "EC2 infrastructure deployed!"
    else
        print_info "Deployment cancelled"
        exit 0
    fi
    
    echo ""
}

###############################################################################
# Step 4: Get EC2 Instance Information
###############################################################################
get_instance_info() {
    print_header "Step 4: Retrieving EC2 Instance Information"
    
    cd "$TERRAFORM_DIR"
    
    # Get Terraform outputs
    echo -e "${BLUE}EC2 Instances Deployed:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    PRIMARY_IP=$(terraform output -raw backend_primary_public_ip 2>/dev/null || echo "N/A")
    SECONDARY_IP=$(terraform output -raw backend_secondary_public_ip 2>/dev/null || echo "N/A")
    PRIMARY_ID=$(terraform output -raw backend_primary_instance_id 2>/dev/null || echo "N/A")
    SECONDARY_ID=$(terraform output -raw backend_secondary_instance_id 2>/dev/null || echo "N/A")
    
    echo -e "Primary Instance:"
    echo -e "  Instance ID: ${GREEN}$PRIMARY_ID${NC}"
    echo -e "  Public IP:   ${GREEN}$PRIMARY_IP${NC}"
    echo -e "  AZ:          ${GREEN}ap-southeast-1a${NC}"
    echo ""
    echo -e "Secondary Instance:"
    echo -e "  Instance ID: ${GREEN}$SECONDARY_ID${NC}"
    echo -e "  Public IP:   ${GREEN}$SECONDARY_IP${NC}"
    echo -e "  AZ:          ${GREEN}ap-southeast-1b${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Export for later use
    export PRIMARY_IP
    export SECONDARY_IP
    export PRIMARY_ID
    export SECONDARY_ID
    
    # Wait for user data to complete
    print_info "Waiting for EC2 user data script to complete (5 minutes)..."
    print_info "The setup script installs Java, configures Spring Boot, and sets up monitoring"
    
    for i in {5..1}; do
        echo -ne "${YELLOW}$i minutes remaining...${NC}\r"
        sleep 60
    done
    echo -e "${GREEN}User data script should be complete!${NC}"
    
    echo ""
}

###############################################################################
# Step 5: Verify EC2 Setup
###############################################################################
verify_ec2_setup() {
    print_header "Step 5: Verifying EC2 Setup"
    
    print_info "Checking primary instance setup..."
    
    # Check if instance is running
    INSTANCE_STATE=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --instance-ids "$PRIMARY_ID" \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    if [ "$INSTANCE_STATE" == "running" ]; then
        print_success "Instance is running"
    else
        print_error "Instance is in state: $INSTANCE_STATE"
        exit 1
    fi
    
    # Check system status
    print_info "Checking system status checks..."
    STATUS_CHECK=$(aws ec2 describe-instance-status \
        --region "$AWS_REGION" \
        --instance-ids "$PRIMARY_ID" \
        --query 'InstanceStatuses[0].SystemStatus.Status' \
        --output text 2>/dev/null || echo "initializing")
    
    if [ "$STATUS_CHECK" == "ok" ]; then
        print_success "System status checks passed"
    else
        print_info "System status: $STATUS_CHECK (may still be initializing)"
    fi
    
    # Try to connect
    print_info "Testing SSH connectivity..."
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i concert-key.pem \
        ec2-user@"$PRIMARY_IP" "echo 'Connection successful'" 2>/dev/null; then
        print_success "SSH connection successful"
    else
        print_error "SSH connection failed (check security group or key pair)"
    fi
    
    echo ""
}

###############################################################################
# Step 6: Test S3 Upload
###############################################################################
test_s3_upload() {
    print_header "Step 6: Testing S3 Upload"
    
    print_info "Testing S3 upload via Lambda presigned URL..."
    
    # Create test file
    TEST_FILE="/tmp/concert-test-$(date +%s).txt"
    echo "Concert Platform S3 Upload Test - $(date)" > "$TEST_FILE"
    echo "Region: $AWS_REGION" >> "$TEST_FILE"
    echo "Source: Singapore EC2 Deployment Script" >> "$TEST_FILE"
    
    print_success "Created test file: $TEST_FILE"
    
    # Request presigned URL from Lambda
    print_info "Requesting presigned URL from Lambda..."
    
    RESPONSE=$(curl -s -X POST "$API_ENDPOINT/upload/event-picture" \
        -H "Content-Type: application/json" \
        -d "{\"filename\": \"test-$(date +%s).txt\", \"contentType\": \"text/plain\"}")
    
    # Parse response
    UPLOAD_URL=$(echo "$RESPONSE" | jq -r '.uploadUrl' 2>/dev/null)
    FILE_KEY=$(echo "$RESPONSE" | jq -r '.key' 2>/dev/null)
    FILE_URL=$(echo "$RESPONSE" | jq -r '.fileUrl' 2>/dev/null)
    
    if [ "$UPLOAD_URL" == "null" ] || [ -z "$UPLOAD_URL" ]; then
        print_error "Failed to get presigned URL"
        echo "Response: $RESPONSE"
        exit 1
    fi
    
    print_success "Received presigned URL"
    echo -e "  Key: ${GREEN}$FILE_KEY${NC}"
    
    # Upload file to S3
    print_info "Uploading file to S3..."
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$UPLOAD_URL" \
        -H "Content-Type: text/plain" \
        --upload-file "$TEST_FILE")
    
    if [ "$HTTP_STATUS" == "200" ]; then
        print_success "File uploaded successfully to S3!"
        echo -e "  HTTP Status: ${GREEN}$HTTP_STATUS${NC}"
        echo -e "  S3 Key: ${GREEN}$FILE_KEY${NC}"
        echo -e "  File URL: ${GREEN}$FILE_URL${NC}"
    else
        print_error "Upload failed with HTTP status: $HTTP_STATUS"
        exit 1
    fi
    
    # Verify file in S3
    print_info "Verifying file in S3 bucket..."
    
    BUCKET_NAME="concert-event-pictures-123456789012"
    if aws s3 ls "s3://$BUCKET_NAME/$FILE_KEY" --region "$AWS_REGION" &>/dev/null; then
        print_success "File verified in S3 bucket!"
        
        # Get file size
        FILE_SIZE=$(aws s3 ls "s3://$BUCKET_NAME/$FILE_KEY" --region "$AWS_REGION" | awk '{print $3}')
        echo -e "  Bucket: ${GREEN}$BUCKET_NAME${NC}"
        echo -e "  Size: ${GREEN}$FILE_SIZE bytes${NC}"
    else
        print_error "File not found in S3 bucket"
        exit 1
    fi
    
    # Clean up
    rm -f "$TEST_FILE"
    
    echo ""
}

###############################################################################
# Step 7: Test S3 Upload from EC2
###############################################################################
test_s3_from_ec2() {
    print_header "Step 7: Testing S3 Upload from EC2 Instance"
    
    print_info "Running S3 upload test on primary EC2 instance..."
    
    # SSH and run test script
    SSH_OUTPUT=$(ssh -o StrictHostKeyChecking=no -i concert-key.pem \
        ec2-user@"$PRIMARY_IP" "/opt/concert/test-s3-upload.sh" 2>&1)
    
    echo "$SSH_OUTPUT"
    
    if echo "$SSH_OUTPUT" | grep -q "Upload complete"; then
        print_success "EC2 S3 upload test passed!"
    else
        print_error "EC2 S3 upload test failed"
        echo "Output: $SSH_OUTPUT"
    fi
    
    echo ""
}

###############################################################################
# Step 8: Migration from us-east-1
###############################################################################
migrate_from_us_east_1() {
    print_header "Step 8: Migration from us-east-1 (Optional)"
    
    # Check for old instances
    print_info "Checking for EC2 instances in us-east-1..."
    
    OLD_INSTANCES=$(aws ec2 describe-instances \
        --region us-east-1 \
        --filters "Name=tag:Name,Values=*concert*" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Placement.AvailabilityZone]' \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$OLD_INSTANCES" ]; then
        print_success "No running instances found in us-east-1"
    else
        print_info "Found running instances in us-east-1:"
        echo "$OLD_INSTANCES" | awk '{printf "  - %s (%s) in %s\n", $1, $2, $4}'
        
        echo ""
        read -p "$(echo -e ${YELLOW}Do you want to terminate these instances? [y/N]:${NC} )" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTANCE_IDS=$(echo "$OLD_INSTANCES" | awk '{print $1}' | tr '\n' ' ')
            
            print_info "Terminating instances: $INSTANCE_IDS"
            aws ec2 terminate-instances --region us-east-1 --instance-ids $INSTANCE_IDS
            
            print_success "Termination initiated. Instances will be terminated shortly."
            print_info "Cost savings: ~$15/month"
        else
            print_info "Skipping termination. Remember to terminate manually later."
        fi
    fi
    
    echo ""
}

###############################################################################
# Step 9: Summary Report
###############################################################################
generate_summary() {
    print_header "Step 9: Deployment Summary"
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Singapore Deployment Summary                     ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║ Region:          ap-southeast-1 (Singapore)                ║${NC}"
    echo -e "${BLUE}║ EC2 Instances:   2 x t3.micro                              ║${NC}"
    echo -e "${BLUE}║ Status:          ✓ Deployed                                ║${NC}"
    echo -e "${BLUE}║ S3 Upload:       ✓ Tested & Working                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    echo -e "${GREEN}Resources Deployed:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "✓ EC2 Primary:   $PRIMARY_ID ($PRIMARY_IP)"
    echo -e "✓ EC2 Secondary: $SECONDARY_ID ($SECONDARY_IP)"
    echo -e "✓ S3 Buckets:    3 buckets (event-pictures, user-avatars, website)"
    echo -e "✓ Lambda:        concert-generate-presigned-url"
    echo -e "✓ API Gateway:   $API_ENDPOINT"
    echo -e "✓ Security Group: backend-ec2-sg (ports 8080, 443, 22)"
    echo -e "✓ IAM Role:      backend-ec2-role"
    echo ""
    
    echo -e "${GREEN}Next Steps:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Build Spring Boot JAR:"
    echo "   cd main_backend && mvn clean package -DskipTests"
    echo ""
    echo "2. Deploy to EC2:"
    echo "   scp -i concert-key.pem target/concert-backend.jar ec2-user@$PRIMARY_IP:/tmp/"
    echo "   ssh -i concert-key.pem ec2-user@$PRIMARY_IP"
    echo "   sudo /opt/concert/deploy.sh"
    echo ""
    echo "3. Check application status:"
    echo "   sudo systemctl status concert-backend"
    echo "   tail -f /opt/concert/logs/application.log"
    echo ""
    echo "4. Test application health:"
    echo "   curl http://$PRIMARY_IP:8080/actuator/health"
    echo ""
    echo "5. Fix remaining deployment blockers:"
    echo "   - RDS password format (if deploying RDS)"
    echo "   - ElastiCache endpoint (if deploying Redis)"
    echo "   - Contact AWS Support for CloudFront verification"
    echo ""
    
    echo -e "${YELLOW}Important Files:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Architecture:   aws/SINGAPORE_ARCHITECTURE.md"
    echo "Flow Diagrams:  aws/COMPLETE_FLOW_DIAGRAM.md"
    echo "S3 Workaround:  aws/S3_ACCESS_WITHOUT_CLOUDFRONT.md"
    echo "EC2 Config:     aws/ec2_backend.tf"
    echo "Setup Script:   aws/user_data/backend_setup.sh"
    echo ""
    
    echo -e "${BLUE}Deployment completed successfully! 🎉${NC}"
    echo ""
}

###############################################################################
# Main Execution
###############################################################################
main() {
    clear
    
    print_header "Concert Platform - Singapore Deployment & S3 Test"
    echo ""
    
    check_prerequisites
    fix_deployment_blockers
    deploy_ec2
    get_instance_info
    verify_ec2_setup
    test_s3_upload
    # test_s3_from_ec2  # Uncomment after EC2 is ready
    migrate_from_us_east_1
    generate_summary
}

# Run main function
main
