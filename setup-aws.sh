#!/bin/bash

# AWS Setup Helper Script
# This script automates the AWS credential configuration and initial setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "\n${GREEN}✓ Step $1: $2${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    exit 1
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "1" "Checking prerequisites"
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("AWS CLI")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("Docker")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("Git")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing tools: ${missing_tools[*]}. Please install them first."
    fi
    
    echo -e "  ${GREEN}✓ AWS CLI${NC} $(aws --version)"
    echo -e "  ${GREEN}✓ Terraform${NC} $(terraform version -json | grep terraform_version | cut -d'"' -f4)"
    echo -e "  ${GREEN}✓ Docker${NC} $(docker --version)"
    echo -e "  ${GREEN}✓ Git${NC} $(git --version)"
}

# Configure AWS CLI
configure_aws() {
    print_step "2" "Configuring AWS CLI"
    
    # Check if already configured
    if aws sts get-caller-identity &> /dev/null; then
        print_info "AWS credentials already configured"
        aws sts get-caller-identity
        return 0
    fi
    
    print_warning "AWS credentials not found"
    echo ""
    echo "Run the following command and enter your AWS credentials:"
    echo ""
    echo "  ${YELLOW}aws configure${NC}"
    echo ""
    echo "You'll need:"
    echo "  • AWS Access Key ID (from AWS Console)"
    echo "  • AWS Secret Access Key (save this securely!)"
    echo "  • Default region (e.g., us-east-1)"
    echo "  • Default output format: json"
    echo ""
    read -p "Press ENTER when you've completed 'aws configure': "
    
    # Verify configuration
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS configuration failed. Please try again."
    fi
}

# Setup Terraform variables
setup_terraform() {
    print_step "3" "Setting up Terraform"
    
    cd aws || print_error "Cannot find 'aws' directory"
    
    if [ ! -f terraform.tfvars ]; then
        print_info "Creating terraform.tfvars from template"
        cp terraform.tfvars.example terraform.tfvars
        
        # Get AWS Account ID
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        AWS_REGION=${AWS_REGION:-us-east-1}
        
        print_warning "terraform.tfvars created with defaults"
        echo ""
        echo "📝 REQUIRED: Edit terraform.tfvars and update:"
        echo "  • db_password - Change to a strong password!"
        echo "  • backend_image_uri - Will be: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/concert/concert-backend:latest"
        echo "  • frontend_image_uri - Will be: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/concert/concert-frontend:latest"
        echo ""
        read -p "Press ENTER when you've updated terraform.tfvars (nano aws/terraform.tfvars): "
    else
        print_info "terraform.tfvars already exists"
    fi
    
    cd ..
}

# Initialize Terraform
init_terraform() {
    print_step "4" "Initializing Terraform"
    
    cd aws || print_error "Cannot find 'aws' directory"
    
    terraform init
    
    cd ..
}

# Show summary
show_summary() {
    print_header "AWS Setup Complete! 🎉"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Edit configuration:"
    echo "     ${YELLOW}nano aws/terraform.tfvars${NC}"
    echo ""
    echo "  2. Build and push Docker images:"
    echo "     ${YELLOW}cd aws && make aws-build-all && cd ..${NC}"
    echo ""
    echo "  3. Review the deployment plan:"
    echo "     ${YELLOW}cd aws && terraform plan && cd ..${NC}"
    echo ""
    echo "  4. Deploy to AWS:"
    echo "     ${YELLOW}cd aws && terraform apply && cd ..${NC}"
    echo ""
    echo "  5. Monitor deployment:"
    echo "     ${YELLOW}cd aws && make status && cd ..${NC}"
    echo ""
    echo "For detailed documentation, see:"
    echo "  • AWS_SETUP_GUIDE.md (step-by-step)"
    echo "  • aws/QUICK_START.md (quick reference)"
    echo "  • aws/README.md (comprehensive)"
    echo ""
}

# Main execution
main() {
    print_header "AWS Setup Helper 🚀"
    
    check_prerequisites
    configure_aws
    setup_terraform
    init_terraform
    show_summary
}

# Run main function
main
