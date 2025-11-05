#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     EC2 + RDS Deployment (~\$27-30/month)                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Config
REGION="us-east-1"
VPC_ID="vpc-09eb1678195d18797"
AMI_ID="ami-0e2c8caa4b6378d8c"
INSTANCE_TYPE="t3.small"
KEY_NAME="Ja"
KEY_PATH="/Users/putinan/development/DevOps/develop/aws/Ja.pem"
ECR_IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest"
DB_NAME="concert_db"
DB_USER="concert"
DB_PASS=$(openssl rand -base64 20 | tr -d "=+/" | cut -c1-20)

echo -e "${BLUE}🔍 Step 1: Setup security groups...${NC}"

# Get or create EC2 security group
EC2_SG=$(aws ec2 describe-security-groups \
  --region ${REGION} \
  --filters Name=group-name,Values=concert-ec2 Name=vpc-id,Values=${VPC_ID} \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [ "$EC2_SG" == "None" ] || [ -z "$EC2_SG" ]; then
  EC2_SG=$(aws ec2 create-security-group \
    --region ${REGION} \
    --group-name concert-ec2 \
    --description "Concert EC2" \
    --vpc-id ${VPC_ID} \
    --query 'GroupId' --output text)
  echo "  Created EC2 SG: ${EC2_SG}"
else
  echo "  Using EC2 SG: ${EC2_SG}"
fi

# Open ports
aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${EC2_SG} --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${EC2_SG} --protocol tcp --port 8080 --cidr 0.0.0.0/0 2>/dev/null || true

# Get or create RDS security group
RDS_SG=$(aws ec2 describe-security-groups \
  --region ${REGION} \
  --filters Name=group-name,Values=concert-rds Name=vpc-id,Values=${VPC_ID} \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [ "$RDS_SG" == "None" ] || [ -z "$RDS_SG" ]; then
  RDS_SG=$(aws ec2 create-security-group \
    --region ${REGION} \
    --group-name concert-rds \
    --description "Concert RDS" \
    --vpc-id ${VPC_ID} \
    --query 'GroupId' --output text)
  echo "  Created RDS SG: ${RDS_SG}"
else
  echo "  Using RDS SG: ${RDS_SG}"
fi

# Allow EC2 to access RDS
aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${RDS_SG} --protocol tcp --port 3306 --source-group ${EC2_SG} 2>/dev/null || true

echo ""
echo -e "${BLUE}💾 Step 2: Create RDS database...${NC}"

# Get subnets
SUBNETS=$(aws ec2 describe-subnets --region ${REGION} --filters Name=vpc-id,Values=${VPC_ID} --query 'Subnets[*].SubnetId' --output text)
SUBNET1=$(echo $SUBNETS | awk '{print $1}')
SUBNET2=$(echo $SUBNETS | awk '{print $2}')

# Create subnet group
aws rds create-db-subnet-group \
  --region ${REGION} \
  --db-subnet-group-name concert-db-subnetgroup \
  --db-subnet-group-description "Concert DB" \
  --subnet-ids ${SUBNET1} ${SUBNET2} 2>/dev/null || echo "  Subnet group exists"

# Check if DB exists
DB_STATUS=$(aws rds describe-db-instances --region ${REGION} --db-instance-identifier concert-db --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "none")

if [ "$DB_STATUS" == "none" ]; then
  echo "  Creating RDS db.t3.micro (5-10 min)..."
  aws rds create-db-instance \
    --region ${REGION} \
    --db-instance-identifier concert-db \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.0.39 \
    --master-username ${DB_USER} \
    --master-user-password ${DB_PASS} \
    --allocated-storage 20 \
    --storage-type gp3 \
    --db-subnet-group-name concert-db-subnetgroup \
    --vpc-security-group-ids ${RDS_SG} \
    --no-publicly-accessible \
    --backup-retention-period 7 \
    --db-name ${DB_NAME} > /dev/null
  
  aws rds wait db-instance-available --region ${REGION} --db-instance-identifier concert-db
else
  echo "  Database exists (${DB_STATUS})"
  if [ "$DB_STATUS" != "available" ]; then
    echo "  Waiting for database..."
    aws rds wait db-instance-available --region ${REGION} --db-instance-identifier concert-db
  fi
  # Get existing password from user or use new one
  echo "  ⚠️  Using new generated password (update if needed)"
fi

DB_ENDPOINT=$(aws rds describe-db-instances --region ${REGION} --db-instance-identifier concert-db --query 'DBInstances[0].Endpoint.Address' --output text)
echo "  ✅ Database: ${DB_ENDPOINT}"

echo ""
echo -e "${BLUE}🚀 Step 3: Launch EC2...${NC}"

USER_DATA='#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user'

INSTANCE_ID=$(aws ec2 run-instances \
  --region ${REGION} \
  --image-id ${AMI_ID} \
  --instance-type ${INSTANCE_TYPE} \
  --key-name ${KEY_NAME} \
  --security-group-ids ${EC2_SG} \
  --subnet-id ${SUBNET1} \
  --user-data "${USER_DATA}" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-api}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "  Instance: ${INSTANCE_ID}"
aws ec2 wait instance-running --region ${REGION} --instance-ids ${INSTANCE_ID}

PUBLIC_IP=$(aws ec2 describe-instances --region ${REGION} --instance-ids ${INSTANCE_ID} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "  ✅ IP: ${PUBLIC_IP}"

echo ""
echo -e "${BLUE}⏳ Step 4: Wait for SSH (90s)...${NC}"
sleep 90

echo ""
echo -e "${BLUE}🐳 Step 5: Deploy application...${NC}"

ECR_PASS=$(aws ecr get-login-password --region ${REGION})

ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} bash <<EOSSH
# Wait for Docker
for i in {1..10}; do
  docker --version 2>/dev/null && break
  sleep 5
done

# Login and deploy
echo "${ECR_PASS}" | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker pull ${ECR_IMAGE}
docker run -d --name concert-api -p 8080:8080 --restart unless-stopped \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://${DB_ENDPOINT}:3306/${DB_NAME} \
  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
  -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO=update \
  ${ECR_IMAGE}
EOSSH

echo "  ✅ Deployed"

echo ""
echo -e "${BLUE}🏥 Step 6: Health check...${NC}"
sleep 30

for i in {1..6}; do
  if curl -sf http://${PUBLIC_IP}:8080/health >/dev/null; then
    echo -e "  ${GREEN}✅ Healthy!${NC}"
    break
  fi
  [ $i -eq 6 ] && echo -e "  ${YELLOW}⚠️  Timeout (may still be starting)${NC}"
  sleep 10
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              ✅ DEPLOYMENT COMPLETE                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}API Endpoint:${NC} http://${PUBLIC_IP}:8080"
echo -e "${GREEN}Test:${NC} curl http://${PUBLIC_IP}:8080/health"
echo ""
echo -e "${BLUE}Database:${NC}"
echo "  Endpoint: ${DB_ENDPOINT}"
echo "  User: ${DB_USER}"
echo "  Pass: ${DB_PASS}"
echo "  Name: ${DB_NAME}"
echo ""
echo -e "${BLUE}Resources:${NC}"
echo "  EC2: ${INSTANCE_ID}"
echo "  RDS: concert-db"
echo "  Cost: ~\$27-30/month"
echo ""
