#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Simple EC2 + RDS Deployment (Default VPC)            ║"
echo "║     Cost: ~\$27-30/month                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
REGION="us-east-1"
VPC_ID="vpc-09eb1678195d18797"  # Default VPC (us-east-1)
AMI_ID="ami-0e2c8caa4b6378d8c"  # Amazon Linux 2023 (us-east-1)
INSTANCE_TYPE="t3.small"
KEY_NAME="Ja"
KEY_PATH="/Users/putinan/development/DevOps/develop/aws/Ja.pem"
ECR_IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest"
DB_NAME="concert_db"
DB_USER="concert"
DB_PASS=$(openssl rand -base64 20 | tr -d "=+/" | cut -c1-20)

echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Region: ${REGION}"
echo "  VPC: ${VPC_ID} (default)"
echo "  Instance: ${INSTANCE_TYPE}"
echo "  Database: db.t3.micro MySQL 8.0"
echo "  Estimated cost: ~\$27-30/month"
echo ""

# Get default subnets
echo -e "${BLUE}🔍 Step 1/6: Getting VPC subnets...${NC}"
SUBNETS=$(aws ec2 --region ${REGION} describe-subnets \
  --region ${REGION} \
  --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'Subnets[*].SubnetId' \
  --output text)

SUBNET_1=$(echo $SUBNETS | awk '{print $1}')
SUBNET_2=$(echo $SUBNETS | awk '{print $2}')

echo "  ✅ Subnet 1: ${SUBNET_1}"
echo "  ✅ Subnet 2: ${SUBNET_2}"
echo ""

# Create Security Groups
echo -e "${BLUE}🔒 Step 2/6: Creating security groups...${NC}"

# EC2 Security Group
EC2_SG_ID=$(aws ec2 --region ${REGION} describe-security-groups \
  --filters "Name=group-name,Values=concert-ec2-sg" "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null)

if [ "$EC2_SG_ID" != "" ] && [ "$EC2_SG_ID" != "None" ]; then
  echo "  ✅ Using existing EC2 security group: ${EC2_SG_ID}"
  
  # Ensure ports are open
  aws ec2 --region ${REGION} authorize-security-group-ingress \
    --group-id ${EC2_SG_ID} \
    --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true
  
  aws ec2 --region ${REGION} authorize-security-group-ingress \
    --group-id ${EC2_SG_ID} \
    --protocol tcp --port 8080 --cidr 0.0.0.0/0 2>/dev/null || true
else
  EC2_SG_ID=$(aws ec2 --region ${REGION} create-security-group \
    --group-name concert-ec2-sg \
    --description "Security group for Concert API EC2" \
    --vpc-id ${VPC_ID} \
    --output text)
  
  aws ec2 --region ${REGION} authorize-security-group-ingress \
    --group-id ${EC2_SG_ID} \
    --protocol tcp --port 22 --cidr 0.0.0.0/0
  
  aws ec2 --region ${REGION} authorize-security-group-ingress \
    --group-id ${EC2_SG_ID} \
    --protocol tcp --port 8080 --cidr 0.0.0.0/0
  
  echo "  ✅ Created EC2 security group: ${EC2_SG_ID}"
fi

# RDS Security Group
RDS_SG_ID=$(aws ec2 --region ${REGION} describe-security-groups \
  --filters "Name=group-name,Values=concert-rds-sg" "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null)

if [ "$RDS_SG_ID" != "" ] && [ "$RDS_SG_ID" != "None" ]; then
  echo "  ✅ Using existing RDS security group: ${RDS_SG_ID}"
else
  RDS_SG_ID=$(aws ec2 --region ${REGION} create-security-group \
    --group-name concert-rds-sg \
    --description "Security group for Concert RDS" \
    --vpc-id ${VPC_ID} \
    --output text)
  
  echo "  ✅ Created RDS security group: ${RDS_SG_ID}"
fi

# Allow EC2 to access RDS
aws ec2 --region ${REGION} authorize-security-group-ingress \
  --group-id ${RDS_SG_ID} \
  --protocol tcp --port 3306 \
  --source-group ${EC2_SG_ID} 2>/dev/null || true

echo ""

# Create RDS Subnet Group
echo -e "${BLUE}💾 Step 3/6: Creating RDS database...${NC}"

DB_SUBNET_GROUP="concert-db-subnet-group"
aws rds --region ${REGION} create-db-subnet-group \
  --db-subnet-group-name ${DB_SUBNET_GROUP} \
  --db-subnet-group-description "Subnet group for Concert DB" \
  --subnet-ids ${SUBNET_1} ${SUBNET_2} 2>/dev/null || echo "  ℹ️  Subnet group already exists"

# Create RDS Instance
DB_INSTANCE="concert-db"
DB_EXISTS=$(aws rds --region ${REGION} describe-db-instances \
  --db-instance-identifier ${DB_INSTANCE} \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text 2>/dev/null || echo "")

if [ "$DB_EXISTS" != "" ]; then
  echo "  ℹ️  Database '${DB_INSTANCE}' already exists (${DB_EXISTS})"
  if [ "$DB_EXISTS" == "available" ]; then
    DB_ENDPOINT=$(aws rds --region ${REGION} describe-db-instances \
      --db-instance-identifier ${DB_INSTANCE} \
      --query 'DBInstances[0].Endpoint.Address' \
      --output text)
    echo "  ✅ Database endpoint: ${DB_ENDPOINT}"
  else
    echo "  ⏳ Waiting for database to be available..."
    aws rds --region ${REGION} wait db-instance-available --db-instance-identifier ${DB_INSTANCE}
    DB_ENDPOINT=$(aws rds --region ${REGION} describe-db-instances \
      --db-instance-identifier ${DB_INSTANCE} \
      --query 'DBInstances[0].Endpoint.Address' \
      --output text)
    echo "  ✅ Database ready: ${DB_ENDPOINT}"
  fi
else
  echo "  Creating RDS MySQL db.t3.micro..."
  aws rds --region ${REGION} create-db-instance \
    --db-instance-identifier ${DB_INSTANCE} \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.0.39 \
    --master-username ${DB_USER} \
    --master-user-password ${DB_PASS} \
    --allocated-storage 20 \
    --storage-type gp3 \
    --db-subnet-group-name ${DB_SUBNET_GROUP} \
    --vpc-security-group-ids ${RDS_SG_ID} \
    --no-publicly-accessible \
    --backup-retention-period 7 \
    --no-multi-az \
    --db-name ${DB_NAME} \
    --storage-encrypted > /dev/null
  
  echo "  ⏳ Waiting for database creation (5-10 minutes)..."
  aws rds --region ${REGION} wait db-instance-available --db-instance-identifier ${DB_INSTANCE}
  
  DB_ENDPOINT=$(aws rds --region ${REGION} describe-db-instances \
    --db-instance-identifier ${DB_INSTANCE} \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
  
  echo "  ✅ Database created: ${DB_ENDPOINT}"
fi

echo ""

# Launch EC2
echo -e "${BLUE}🚀 Step 4/6: Launching EC2 instance...${NC}"

USER_DATA=$(cat <<'EOF'
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
echo "Setup complete" > /tmp/setup-complete.txt
EOF
)

INSTANCE_ID=$(aws ec2 --region ${REGION} run-instances \
  --image-id ${AMI_ID} \
  --instance-type ${INSTANCE_TYPE} \
  --key-name ${KEY_NAME} \
  --security-group-ids ${EC2_SG_ID} \
  --subnet-id ${SUBNET_1} \
  --user-data "${USER_DATA}" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=concert-api}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "  ✅ Instance launched: ${INSTANCE_ID}"
echo "  ⏳ Waiting for instance to start..."

aws ec2 --region ${REGION} wait instance-running --instance-ids ${INSTANCE_ID}

PUBLIC_IP=$(aws ec2 --region ${REGION} describe-instances \
  --instance-ids ${INSTANCE_ID} \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "  ✅ Instance ready: ${PUBLIC_IP}"
echo ""

# Wait for SSH
echo -e "${BLUE}⏳ Step 5/6: Waiting for SSH (90 seconds)...${NC}"
sleep 90

echo ""

# Deploy Application
echo -e "${BLUE}🐳 Step 6/6: Deploying Spring Boot API...${NC}"

ECR_PASSWORD=$(aws ecr get-login-password --region ${REGION})

ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} <<DEPLOY_EOF
# Wait for Docker
for i in {1..10}; do
  if docker --version 2>/dev/null; then
    break
  fi
  echo "Waiting for Docker... \$i/10"
  sleep 5
done

# Login to ECR
echo ${ECR_PASSWORD} | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Pull and run
docker pull ${ECR_IMAGE}

docker run -d \
  --name concert-api \
  -p 8080:8080 \
  --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://${DB_ENDPOINT}:3306/${DB_NAME} \
  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
  -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO=update \
  ${ECR_IMAGE}

echo "Container started"
DEPLOY_EOF

echo "  ✅ Application deployed"
echo ""

# Health Check
echo -e "${BLUE}🏥 Health check...${NC}"
sleep 30

for i in {1..6}; do
  if curl -sf http://${PUBLIC_IP}:8080/health > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ API is healthy!${NC}"
    break
  fi
  if [ $i -eq 6 ]; then
    echo -e "  ${YELLOW}⚠️  Health check timeout (app may still be starting)${NC}"
  fi
  sleep 10
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
echo "   curl http://${PUBLIC_IP}:8080/health"
echo "   curl http://${PUBLIC_IP}:8080/api/auth/test"
echo ""
echo -e "${GREEN}💾 Database:${NC}"
echo "   Endpoint: ${DB_ENDPOINT}"
echo "   Database: ${DB_NAME}"
echo "   Username: ${DB_USER}"
echo "   Password: ${DB_PASS}"
echo ""
echo -e "${GREEN}🔧 Management:${NC}"
echo "   ssh -i ${KEY_PATH} ec2-user@${PUBLIC_IP}"
echo "   docker logs -f concert-api"
echo ""
echo -e "${BLUE}💰 Monthly Cost Estimate:${NC}"
echo "   EC2 t3.small:     ~\$15/month"
echo "   RDS db.t3.micro:  ~\$12-15/month"
echo "   Total:            ~\$27-30/month"
echo ""
echo -e "${GREEN}Resources Created:${NC}"
echo "   EC2 Instance: ${INSTANCE_ID}"
echo "   RDS Database: ${DB_INSTANCE}"
echo "   EC2 Security Group: ${EC2_SG_ID}"
echo "   RDS Security Group: ${RDS_SG_ID}"
echo ""
