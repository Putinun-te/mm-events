#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Deploy EC2 with Existing RDS (~\$15/month)                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Config - Use existing serverless VPC and RDS
REGION="us-east-1"
VPC_ID="vpc-0a5017f4d8e1962ee"
PUBLIC_SUBNET="subnet-0b81a251ebd23fa1a"  # us-east-1b public
AMI_ID="ami-0e2c8caa4b6378d8c"
INSTANCE_TYPE="t3.small"
KEY_NAME="Ja"
KEY_PATH="/Users/putinan/development/DevOps/develop/aws/Ja.pem"
ECR_IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest"
RDS_ENDPOINT="concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com"
DB_NAME="concert_db"

echo -e "${BLUE}Using existing resources:${NC}"
echo "  VPC: ${VPC_ID} (serverless)"
echo "  RDS: ${RDS_ENDPOINT}"
echo "  Cost: ~\$15/month (EC2 only)"
echo ""

# Get database credentials from Secrets Manager
echo -e "${BLUE}🔐 Getting database credentials...${NC}"
DB_SECRET=$(aws secretsmanager get-secret-value --region ${REGION} --secret-id concert-prod/database --query SecretString --output text)
DB_USER=$(echo ${DB_SECRET} | jq -r '.username')
DB_PASS=$(echo ${DB_SECRET} | jq -r '.password')
echo "  ✅ Retrieved"
echo ""

# Get or create security group
echo -e "${BLUE}🔒 Setup security group...${NC}"
SG_ID=$(aws ec2 describe-security-groups --region ${REGION} --filters Name=group-name,Values=concert-ec2-app Name=vpc-id,Values=${VPC_ID} --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
  SG_ID=$(aws ec2 create-security-group --region ${REGION} --group-name concert-ec2-app --description "Concert EC2 App" --vpc-id ${VPC_ID} --query 'GroupId' --output text)
  echo "  Created: ${SG_ID}"
  
  aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${SG_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${SG_ID} --protocol tcp --port 8080 --cidr 0.0.0.0/0
  echo "  Opened ports 22, 8080"
else
  echo "  Using: ${SG_ID}"
  aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${SG_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true
  aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${SG_ID} --protocol tcp --port 8080 --cidr 0.0.0.0/0 2>/dev/null || true
fi
echo ""

# Update RDS security group to allow EC2 access
echo -e "${BLUE}🔓 Allow EC2 to access RDS...${NC}"
RDS_SG="sg-0491f08873d3e0945"
aws ec2 authorize-security-group-ingress --region ${REGION} --group-id ${RDS_SG} --protocol tcp --port 3306 --source-group ${SG_ID} 2>/dev/null && echo "  ✅ Access granted" || echo "  ℹ️  Already allowed"
echo ""

# Launch EC2
echo -e "${BLUE}🚀 Launching EC2...${NC}"
USER_DATA='#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user'

INSTANCE_ID=$(aws ec2 run-instances --region ${REGION} \
  --image-id ${AMI_ID} \
  --instance-type ${INSTANCE_TYPE} \
  --key-name ${KEY_NAME} \
  --security-group-ids ${SG_ID} \
  --subnet-id ${PUBLIC_SUBNET} \
  --user-data "${USER_DATA}" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-api}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "  Instance: ${INSTANCE_ID}"
aws ec2 wait instance-running --region ${REGION} --instance-ids ${INSTANCE_ID}

PUBLIC_IP=$(aws ec2 describe-instances --region ${REGION} --instance-ids ${INSTANCE_ID} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "  ✅ IP: ${PUBLIC_IP}"
echo ""

echo -e "${BLUE}⏳ Waiting for SSH (90s)...${NC}"
sleep 90
echo ""

# Deploy app
echo -e "${BLUE}🐳 Deploying application...${NC}"
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
  -e SPRING_DATASOURCE_URL=jdbc:mysql://${RDS_ENDPOINT}:3306/${DB_NAME} \
  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
  -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO=update \
  ${ECR_IMAGE}
EOSSH

echo "  ✅ Deployed"
echo ""

# Health check
echo -e "${BLUE}🏥 Health check...${NC}"
sleep 30

for i in {1..6}; do
  if curl -sf http://${PUBLIC_IP}:8080/health >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅ API is healthy!${NC}"
    break
  fi
  [ $i -eq 6 ] && echo "  ⚠️  Timeout"
  sleep 10
done

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              ✅ DEPLOYMENT COMPLETE                       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}🌐 API:${NC} http://${PUBLIC_IP}:8080"
echo -e "${GREEN}📝 Test:${NC} curl http://${PUBLIC_IP}:8080/health"
echo ""
echo -e "${BLUE}Resources:${NC}"
echo "  EC2: ${INSTANCE_ID}"
echo "  RDS: concert-prod-db (existing)"
echo "  Cost: ~\$15/month (EC2 only)"
echo ""
