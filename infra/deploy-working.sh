#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Spring Boot API - EC2 Deployment (Working Version)       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
VPC_ID="vpc-0a5017f4d8e1962ee"
PUBLIC_SUBNET="subnet-0b81a251ebd23fa1a"  # us-east-1b public
AMI_ID="ami-0e2c8caa4b6378d8c"  # Amazon Linux 2023
INSTANCE_TYPE="t3.small"
KEY_NAME="Ja"
KEY_PATH="/Users/putinan/development/DevOps/develop/aws/Ja.pem"
ECR_IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2"
RDS_ENDPOINT="concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306"
REDIS_ENDPOINT="concert-prod-cache.h9wuqf.ng.0001.use1.cache.amazonaws.com:6379"
S3_BUCKET="concert-prod-web-123456789012"
COGNITO_POOL="us-east-1_nTZpyinXc"
COGNITO_CLIENT="3hjltdtf1jvg1q80kdqf8vad2"
REGION="us-east-1"

echo -e "${BLUE}🔍 Step 1/5: Creating Security Group...${NC}"

# Check if security group already exists
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=concert-ec2-public" "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || echo "")

if [ "$SG_ID" != "" ] && [ "$SG_ID" != "None" ]; then
  echo "  ✅ Using existing security group: ${SG_ID}"
else
  echo "  Creating new security group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name concert-ec2-public \
    --description "Security group for concert API EC2" \
    --vpc-id ${VPC_ID} \
    --output text)
  echo "  ✅ Created security group: ${SG_ID}"
  
  # Add SSH rule
  aws ec2 authorize-security-group-ingress \
    --group-id ${SG_ID} \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 > /dev/null
  echo "  ✅ Port 22 (SSH) opened"
  
  # Add API rule
  aws ec2 authorize-security-group-ingress \
    --group-id ${SG_ID} \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 > /dev/null
  echo "  ✅ Port 8080 (API) opened"
fi

echo ""
echo -e "${BLUE}🚀 Step 2/5: Launching EC2 instance...${NC}"

# User data script to install Docker
USER_DATA=$(cat <<'EOF'
#!/bin/bash
# Update system
yum update -y

# Install Docker
yum install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install AWS CLI v2 (already installed on AL2023)
# Verify installations
docker --version
aws --version

# Signal completion
echo "Setup complete" > /tmp/setup-complete.txt
EOF
)

# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ${AMI_ID} \
  --instance-type ${INSTANCE_TYPE} \
  --key-name ${KEY_NAME} \
  --security-group-ids ${SG_ID} \
  --subnet-id ${PUBLIC_SUBNET} \
  --associate-public-ip-address \
  --user-data "${USER_DATA}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=concert-api-prod}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "  ✅ Instance launched: ${INSTANCE_ID}"
echo ""

echo -e "${BLUE}⏳ Step 3/5: Waiting for instance (3-4 minutes)...${NC}"
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID}
echo "  ✅ Instance running"

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids ${INSTANCE_ID} \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "  ✅ Public IP: ${PUBLIC_IP}"
echo ""

echo -e "${BLUE}⏳ Waiting for SSH to be ready (60 seconds)...${NC}"
sleep 60

# Wait for Docker to be ready
echo "  Waiting for Docker installation..."
for i in {1..12}; do
  if ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@${PUBLIC_IP} "docker --version" 2>/dev/null; then
    echo "  ✅ Docker ready"
    break
  fi
  if [ $i -eq 12 ]; then
    echo -e "  ${RED}❌ Timeout waiting for Docker${NC}"
    exit 1
  fi
  echo "  Attempt $i/12..."
  sleep 10
done

echo ""
echo -e "${BLUE}📦 Step 4/5: Deploying Spring Boot API...${NC}"

# Get database credentials from Secrets Manager
echo "  Retrieving database credentials..."
DB_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id concert-prod/database-rPD \
  --query SecretString \
  --output text)

DB_USER=$(echo ${DB_SECRET} | jq -r '.username')
DB_PASS=$(echo ${DB_SECRET} | jq -r '.password')

echo "  ✅ Credentials retrieved"

# Get ECR login token
echo "  Logging into ECR..."
ECR_PASSWORD=$(aws ecr get-login-password --region ${REGION})

# Deploy via SSH
echo "  Deploying container..."
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} <<DEPLOY_EOF
# Login to ECR
echo ${ECR_PASSWORD} | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Stop and remove existing container
docker stop concert-api 2>/dev/null || true
docker rm concert-api 2>/dev/null || true

# Pull latest image
docker pull ${ECR_IMAGE}

# Run container
docker run -d \
  --name concert-api \
  -p 8080:8080 \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://${RDS_ENDPOINT}/concert_db \
  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
  -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO=update \
  -e SPRING_DATA_REDIS_HOST=$(echo ${REDIS_ENDPOINT} | cut -d':' -f1) \
  -e SPRING_DATA_REDIS_PORT=$(echo ${REDIS_ENDPOINT} | cut -d':' -f2) \
  -e AWS_REGION=${REGION} \
  -e AWS_COGNITO_USER_POOL_ID=${COGNITO_POOL} \
  -e AWS_COGNITO_CLIENT_ID=${COGNITO_CLIENT} \
  -e AWS_S3_BUCKET=${S3_BUCKET} \
  ${ECR_IMAGE}

echo "Container started"
DEPLOY_EOF

echo "  ✅ Container deployed"
echo ""

echo -e "${BLUE}🏥 Step 5/5: Health check...${NC}"
echo "  Waiting for application to start (30 seconds)..."
sleep 30

# Test health endpoint
for i in {1..6}; do
  if curl -sf http://${PUBLIC_IP}:8080/health > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ API is healthy!${NC}"
    break
  fi
  if [ $i -eq 6 ]; then
    echo -e "  ${RED}⚠️  Health check timeout, but container is running${NC}"
  else
    echo "  Attempt $i/6..."
    sleep 10
  fi
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              ✅ DEPLOYMENT COMPLETE                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}🌐 API Endpoint:${NC}"
echo "   http://${PUBLIC_IP}:8080"
echo ""
echo -e "${GREEN}📝 Test Commands:${NC}"
echo "   # Health check"
echo "   curl http://${PUBLIC_IP}:8080/health"
echo ""
echo "   # Test auth endpoint"
echo "   curl http://${PUBLIC_IP}:8080/api/auth/test"
echo ""
echo -e "${GREEN}🔍 Useful Commands:${NC}"
echo "   # SSH into instance"
echo "   ssh -i ${KEY_PATH} ec2-user@${PUBLIC_IP}"
echo ""
echo "   # Check container logs"
echo "   ssh -i ${KEY_PATH} ec2-user@${PUBLIC_IP} 'docker logs -f concert-api'"
echo ""
echo "   # Check container status"
echo "   ssh -i ${KEY_PATH} ec2-user@${PUBLIC_IP} 'docker ps'"
echo ""
echo -e "${BLUE}💡 Instance Details:${NC}"
echo "   Instance ID: ${INSTANCE_ID}"
echo "   Security Group: ${SG_ID}"
echo "   Subnet: ${PUBLIC_SUBNET}"
echo ""
