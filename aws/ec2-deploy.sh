#!/bin/bash
# EC2 Deployment Helper Script
# This script helps deploy the Concert application to EC2 instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➜ $1${NC}"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AWS_DIR="${SCRIPT_DIR}"

# Check if terraform.tfstate exists
if [ ! -f "${AWS_DIR}/terraform.tfstate" ]; then
    print_error "terraform.tfstate not found. Please run 'terraform apply' first."
    exit 1
fi

# Initialize
print_header "EC2 Deployment Helper"

# Get instances info from Terraform
print_info "Fetching EC2 instances information..."

BACKEND_ID=$(terraform output -raw backend_ec2_instance_id 2>/dev/null || echo "")
BACKEND_IP=$(terraform output -raw backend_ec2_public_ip 2>/dev/null || echo "")
BACKEND_EIP=$(terraform output -raw backend_ec2_eip 2>/dev/null || echo "")

FRONTEND_ID=$(terraform output -raw frontend_ec2_instance_id 2>/dev/null || echo "")
FRONTEND_IP=$(terraform output -raw frontend_ec2_public_ip 2>/dev/null || echo "")
FRONTEND_EIP=$(terraform output -raw frontend_ec2_eip 2>/dev/null || echo "")

# Display menu
show_menu() {
    echo ""
    echo -e "${BLUE}Available Commands:${NC}"
    echo "1. Show EC2 instances status"
    echo "2. SSH to backend EC2"
    echo "3. SSH to frontend EC2"
    echo "4. Deploy backend container"
    echo "5. Deploy frontend container"
    echo "6. View EC2 logs"
    echo "7. Get deployment addresses"
    echo "8. Monitor instances"
    echo "9. Exit"
    echo ""
    read -p "Select option: " choice
}

# Show status
show_status() {
    print_header "EC2 Instances Status"
    
    if [ ! -z "$BACKEND_ID" ]; then
        print_info "Backend Instance"
        echo "  Instance ID: $BACKEND_ID"
        echo "  Public IP: $BACKEND_IP"
        [ ! -z "$BACKEND_EIP" ] && echo "  Elastic IP: $BACKEND_EIP"
    else
        echo "  Backend EC2 not enabled"
    fi
    
    if [ ! -z "$FRONTEND_ID" ]; then
        print_info "Frontend Instance"
        echo "  Instance ID: $FRONTEND_ID"
        echo "  Public IP: $FRONTEND_IP"
        [ ! -z "$FRONTEND_EIP" ] && echo "  Elastic IP: $FRONTEND_EIP"
    else
        echo "  Frontend EC2 not enabled"
    fi
}

# SSH to backend
ssh_backend() {
    if [ -z "$BACKEND_IP" ]; then
        print_error "Backend EC2 instance not found or not enabled"
        return 1
    fi
    
    KEY_FILE="${AWS_DIR}/concert-key.pem"
    if [ ! -f "$KEY_FILE" ]; then
        print_error "SSH key not found at $KEY_FILE"
        return 1
    fi
    
    print_info "Connecting to backend: $BACKEND_IP"
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"${BACKEND_EIP:-$BACKEND_IP}"
}

# SSH to frontend
ssh_frontend() {
    if [ -z "$FRONTEND_IP" ]; then
        print_error "Frontend EC2 instance not found or not enabled"
        return 1
    fi
    
    KEY_FILE="${AWS_DIR}/concert-key.pem"
    if [ ! -f "$KEY_FILE" ]; then
        print_error "SSH key not found at $KEY_FILE"
        return 1
    fi
    
    print_info "Connecting to frontend: $FRONTEND_IP"
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"${FRONTEND_EIP:-$FRONTEND_IP}"
}

# Deploy backend container
deploy_backend() {
    if [ -z "$BACKEND_IP" ]; then
        print_error "Backend EC2 instance not found or not enabled"
        return 1
    fi
    
    KEY_FILE="${AWS_DIR}/concert-key.pem"
    if [ ! -f "$KEY_FILE" ]; then
        print_error "SSH key not found at $KEY_FILE"
        return 1
    fi
    
    TARGET_IP="${BACKEND_EIP:-$BACKEND_IP}"
    print_info "Deploying backend to $TARGET_IP"
    
    # Get ECR repository URL
    REPO_URL=$(terraform output -raw backend_ecr_repository_url 2>/dev/null)
    
    # Deploy script
    DEPLOY_SCRIPT=$(cat <<'DEPLOY_EOF'
#!/bin/bash
set -e

# Get AWS account and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(ec2-metadata --availability-zone | awk -F= '{print $2}' | sed 's/[a-z]$//')

# Login to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull and run backend image
docker pull $REPO_URL:latest
docker run -d \
  --name concert-backend \
  -p 8080:8080 \
  -e MYSQL_HOST=$DB_HOST \
  -e MYSQL_PORT=3306 \
  -e MYSQL_DB=concert \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=$DB_PASSWORD \
  $REPO_URL:latest

echo "Backend deployed successfully"
DEPLOY_EOF
)
    
    # Execute on remote
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$TARGET_IP" <<EOF
$DEPLOY_SCRIPT
EOF
    
    print_success "Backend deployed"
}

# Deploy frontend container
deploy_frontend() {
    if [ -z "$FRONTEND_IP" ]; then
        print_error "Frontend EC2 instance not found or not enabled"
        return 1
    fi
    
    KEY_FILE="${AWS_DIR}/concert-key.pem"
    if [ ! -f "$KEY_FILE" ]; then
        print_error "SSH key not found at $KEY_FILE"
        return 1
    fi
    
    TARGET_IP="${FRONTEND_EIP:-$FRONTEND_IP}"
    print_info "Deploying frontend to $TARGET_IP"
    
    # Get ECR repository URL
    REPO_URL=$(terraform output -raw frontend_ecr_repository_url 2>/dev/null)
    
    # Deploy script
    DEPLOY_SCRIPT=$(cat <<'DEPLOY_EOF'
#!/bin/bash
set -e

# Get AWS account and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(ec2-metadata --availability-zone | awk -F= '{print $2}' | sed 's/[a-z]$//')

# Login to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull and run frontend image
docker pull $REPO_URL:latest
docker run -d \
  --name concert-frontend \
  -p 3000:3000 \
  -e API_URL=http://backend-ip:8080 \
  $REPO_URL:latest

echo "Frontend deployed successfully"
DEPLOY_EOF
)
    
    # Execute on remote
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$TARGET_IP" <<EOF
$DEPLOY_SCRIPT
EOF
    
    print_success "Frontend deployed"
}

# Show deployment addresses
show_addresses() {
    print_header "Deployment Addresses"
    
    if [ ! -z "$BACKEND_IP" ]; then
        echo -e "${GREEN}Backend:${NC}"
        echo "  SSH: ssh -i concert-key.pem ubuntu@${BACKEND_EIP:-$BACKEND_IP}"
        echo "  API: http://${BACKEND_EIP:-$BACKEND_IP}:8080"
        echo ""
    fi
    
    if [ ! -z "$FRONTEND_IP" ]; then
        echo -e "${GREEN}Frontend:${NC}"
        echo "  SSH: ssh -i concert-key.pem ubuntu@${FRONTEND_EIP:-$FRONTEND_IP}"
        echo "  Web: http://${FRONTEND_EIP:-$FRONTEND_IP}:3000"
        echo ""
    fi
}

# Monitor instances
monitor_instances() {
    print_header "Monitoring EC2 Instances"
    
    if [ ! -z "$BACKEND_ID" ] || [ ! -z "$FRONTEND_ID" ]; then
        aws ec2 describe-instances \
            --instance-ids ${BACKEND_ID:-""} ${FRONTEND_ID:-""} \
            --region us-east-1 \
            --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,InstanceType]' \
            --output table
    else
        print_error "No EC2 instances found"
    fi
}

# Main loop
while true; do
    show_menu
    
    case $choice in
        1) show_status ;;
        2) ssh_backend ;;
        3) ssh_frontend ;;
        4) deploy_backend ;;
        5) deploy_frontend ;;
        6) echo "CloudWatch logs feature coming soon" ;;
        7) show_addresses ;;
        8) monitor_instances ;;
        9) echo "Exiting..."; exit 0 ;;
        *) print_error "Invalid option" ;;
    esac
done
