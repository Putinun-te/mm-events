#!/bin/bash
set -e

REGION="ap-southeast-1"
KEY_NAME="concert-singapore"
SG_NAME="concert-backend-sg"

echo "🚀 Fresh EC2 deployment..."

# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
echo "VPC: $VPC_ID"

# Get subnet
SUBNET_ID=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
echo "Subnet: $SUBNET_ID"

# Create security group
SG_ID=$(aws ec2 create-security-group --region $REGION --group-name $SG_NAME --description "Concert backend" --vpc-id $VPC_ID --query 'GroupId' --output text 2>/dev/null || aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0 2>/dev/null || true
echo "SG: $SG_ID"

# Launch
INSTANCE_ID=$(aws ec2 run-instances \
  --region $REGION \
  --image-id ami-047126e50991d067b \
  --instance-type t3.small \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-backend}]' \
  --user-data '#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ Instance: $INSTANCE_ID"
echo "⏳ Waiting..."
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID
sleep 40

PUBLIC_IP=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "✅ IP: $PUBLIC_IP"

# Deploy
echo "📦 Deploying backend..."
scp -o StrictHostKeyChecking=no -i concert-singapore.pem main_backend/target/concert-backend-1.0.0.jar ubuntu@$PUBLIC_IP:~/

ssh -o StrictHostKeyChecking=no -i concert-singapore.pem ubuntu@$PUBLIC_IP << 'EOF'
docker run -d \
  --name concert-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -v ~/concert-backend-1.0.0.jar:/app/app.jar \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.c8aqvqzqxqxq.ap-southeast-1.rds.amazonaws.com:3306/concert_db" \
  -e SPRING_DATASOURCE_USERNAME="concert_user" \
  -e SPRING_DATASOURCE_PASSWORD="REDACTED_PASSWORD_A" \
  -e AWS_REGION="ap-southeast-1" \
  eclipse-temurin:21-jre \
  java -jar /app/app.jar
EOF

echo "✅ Done! http://$PUBLIC_IP:8080/actuator/health"
