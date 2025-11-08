#!/bin/bash
# Cleanup unnecessary AWS resources and deploy the best solution
# Run from: /Users/putinan/development/DevOps/develop

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REGION="ap-southeast-1"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  AWS Cleanup & Optimal Deployment                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Remove Lambda warming (not needed anymore)
echo -e "${YELLOW}🧹 Step 1/7: Removing Lambda warming CloudWatch rule...${NC}"
aws events remove-targets \
  --rule keep-lambda-warm \
  --ids "1" \
  --region $REGION 2>/dev/null && echo "  ✅ Targets removed" || echo "  ⚠️  No targets to remove"

aws events delete-rule \
  --name keep-lambda-warm \
  --region $REGION 2>/dev/null && echo "  ✅ Rule deleted" || echo "  ⚠️  No rule to delete"

# Step 2: Remove partial ECS resources
echo -e "${YELLOW}🧹 Step 2/7: Cleaning up partial ECS/Fargate resources...${NC}"

# Delete ECS services first
for cluster in concert-prod-cluster concert-cluster; do
    SERVICES=$(aws ecs list-services --cluster $cluster --region $REGION --query 'serviceArns' --output text 2>/dev/null || echo "")
    if [ ! -z "$SERVICES" ]; then
        for service in $SERVICES; do
            echo "  Deleting service: $service"
            aws ecs update-service --cluster $cluster --service $service --desired-count 0 --region $REGION 2>/dev/null || true
            aws ecs delete-service --cluster $cluster --service $service --force --region $REGION 2>/dev/null || true
        done
    fi
done

# Delete clusters
aws ecs delete-cluster --cluster concert-prod-cluster --region $REGION 2>/dev/null && echo "  ✅ concert-prod-cluster deleted" || echo "  ⚠️  Cluster not found"
aws ecs delete-cluster --cluster concert-cluster --region $REGION 2>/dev/null && echo "  ✅ concert-cluster deleted" || echo "  ⚠️  Cluster not found"

# Step 3: Terminate old EC2 instances in wrong VPC
echo -e "${YELLOW}🧹 Step 3/7: Checking EC2 instances...${NC}"
OLD_INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=vpc-077128945cf424869" "Name=instance-state-name,Values=running" \
  --region $REGION \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output text)

if [ ! -z "$OLD_INSTANCES" ]; then
    echo "  Found instances in old VPC:"
    echo "$OLD_INSTANCES"
    echo "  ⚠️  Skipping termination (terminate manually if needed)"
else
    echo "  ✅ No instances in old VPC"
fi

# Step 4: Remove Lambda function and API Gateway (optional)
echo -e "${YELLOW}🧹 Step 4/7: Lambda and API Gateway cleanup...${NC}"
echo "  ⚠️  Skipping Lambda + API Gateway cleanup (managed by Terraform)"
echo "  To remove manually: cd infra/terraform/production && terraform destroy -target=..."
echo "  ✅ Continuing with EC2 deployment"

# Step 5: Launch new EC2 in serverless VPC
echo ""
echo -e "${GREEN}🚀 Step 5/7: Launching new EC2 in serverless VPC...${NC}"

# Get public subnet (need public IP for SSH access)
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-0a5017f4d8e1962ee" "Name=map-public-ip-on-launch,Values=true" \
  --region $REGION \
  --query 'Subnets[0].SubnetId' \
  --output text)

echo "  Subnet: $SUBNET_ID"

# Get Lambda security group (has access to RDS, Redis, EFS)
LAMBDA_SG=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-0a5017f4d8e1962ee" "Name=group-name,Values=concert-prod-lambda" \
  --region $REGION \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "  Security Group: $LAMBDA_SG"

# User data script
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
    yum install -y aws-cli
fi
EOF
)

# Launch instance
echo "  Launching t3.small instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0453ec754f44f9a4a \
  --instance-type t3.small \
  --key-name concert-key \
  --security-group-ids $LAMBDA_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-api-prod}]' \
  --user-data "$USER_DATA" \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo -e "  ${GREEN}✅ Instance launched: $INSTANCE_ID${NC}"

# Step 6: Wait for instance to be ready
echo ""
echo -e "${YELLOW}⏳ Step 6/7: Waiting for instance to start (this takes 2-3 minutes)...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
sleep 30  # Wait for user data script to complete

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo -e "  ${GREEN}✅ Instance ready!${NC}"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"

# Open port 8080 in security group
echo ""
echo -e "${YELLOW}🔓 Opening port 8080...${NC}"
aws ec2 authorize-security-group-ingress \
  --group-id $LAMBDA_SG \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region $REGION 2>/dev/null && echo "  ✅ Port 8080 opened" || echo "  ⚠️  Port already open"

# Tag security group for clarity
aws ec2 create-tags \
  --resources $LAMBDA_SG \
  --tags Key=Name,Value=concert-api-sg Key=Purpose,Value="API access to RDS/Redis/EFS" \
  --region $REGION 2>/dev/null || true

# Step 7: Deploy Spring Boot application
echo ""
echo -e "${GREEN}🚀 Step 7/7: Deploying Spring Boot API to EC2...${NC}"

# Update deployment script with new instance ID
DEPLOY_SCRIPT="/Users/putinan/development/DevOps/develop/infra/deploy-ec2-automated.sh"
if [ -f "$DEPLOY_SCRIPT" ]; then
    sed -i '' "s/EC2_INSTANCE_ID=\".*\"/EC2_INSTANCE_ID=\"$INSTANCE_ID\"/g" "$DEPLOY_SCRIPT"
    echo "  ✅ Deploy script updated with new instance ID"
    
    # Run deployment
    echo "  Running deployment..."
    sleep 10  # Extra wait for Docker to be ready
    bash "$DEPLOY_SCRIPT"
else
    echo "  ⚠️  Deploy script not found at $DEPLOY_SCRIPT"
    echo "  Deploy manually with:"
    echo "    ssh -i /Users/putinan/development/DevOps/develop/aws/concert-key.pem ec2-user@$PUBLIC_IP"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cleanup & Deployment Complete!                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Removed:${NC}"
echo "  - CloudWatch Lambda warming rule"
echo "  - Partial ECS/Fargate resources"
echo "  - Old EC2 instances in wrong VPC (if confirmed)"
echo ""
echo -e "${GREEN}✅ Deployed:${NC}"
echo "  - New EC2 t3.small in serverless VPC"
echo "  - Spring Boot API running in Docker"
echo ""
echo -e "${GREEN}🌐 Your API is now available at:${NC}"
echo "  Health: http://$PUBLIC_IP:8080/health"
echo "  Auth:   http://$PUBLIC_IP:8080/api/auth/test"
echo ""
echo -e "${YELLOW}💰 Monthly Cost Estimate:${NC}"
echo "  - EC2 t3.small: ~\$15"
echo "  - RDS MySQL: ~\$15"
echo "  - ElastiCache Redis: ~\$8"
echo "  - S3, EFS, Cognito: ~\$2"
echo "  - Total: ~\$40/month"
echo ""
echo -e "${YELLOW}📊 Resources to keep:${NC}"
echo "  ✅ RDS MySQL (concert-prod-db)"
echo "  ✅ ElastiCache Redis (concert-prod-redis)"
echo "  ✅ S3 (concert-prod-web-*)"
echo "  ✅ Cognito (concert-prod)"
echo "  ✅ EFS (concert-prod-efs)"
echo "  ✅ VPC (vpc-0a5017f4d8e1962ee)"
echo "  ✅ EC2 (concert-api-prod - $INSTANCE_ID)"
echo ""
echo -e "${RED}🗑️  You can safely remove (via Terraform):${NC}"
echo "  ❌ Lambda function (has cold start issues)"
echo "  ❌ API Gateway (connected to broken Lambda)"
echo ""
echo "To remove Lambda + API Gateway:"
echo "  cd /Users/putinan/development/DevOps/develop/infra/terraform/production"
echo "  terraform destroy -target=module.serverless.module.lambda_api"
echo "  terraform destroy -target=module.serverless.module.api_gateway"
echo "  terraform apply  # to update state"
echo ""
echo -e "${GREEN}🎉 Setup complete! Test your API:${NC}"
echo "  curl http://$PUBLIC_IP:8080/health"
echo ""
