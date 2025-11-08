#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGION="ap-southeast-1"
VPC_ID="vpc-0f4607ec53e2424b1"
KEY_NAME="JA"

echo -e "${GREEN}🚀 Deploying to Singapore${NC}"

# Get public subnet
SUBNET_ID=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" \
  --query 'Subnets[0].SubnetId' \
  --output text)

echo "Subnet: $SUBNET_ID"

# Get or create security group
SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=concert-backend-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null)

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
  echo "Creating security group..."
  SG_ID=$(aws ec2 create-security-group \
    --region $REGION \
    --group-name concert-backend-sg \
    --description "Concert backend security group" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)
  
  aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0
fi

echo "Security Group: $SG_ID"

# Launch instance
echo "Launching instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region $REGION \
  --image-id ami-047126e50991d067b \
  --instance-type t3.small \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-backend-singapore}]' \
  --user-data '#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo -e "${GREEN}✅ Instance: $INSTANCE_ID${NC}"

# Wait
echo "Waiting for instance..."
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID
sleep 30

PUBLIC_IP=$(aws ec2 describe-instances \
  --region $REGION \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo -e "${GREEN}✅ IP: $PUBLIC_IP${NC}"
echo ""
echo "SSH: ssh -i aws/concert-key.pem ec2-user@$PUBLIC_IP"
echo "Deploy: scp -i aws/concert-key.pem main_backend/target/concert-backend-1.0.0.jar ec2-user@$PUBLIC_IP:~/"
