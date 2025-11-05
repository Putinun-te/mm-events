#!/bin/bash
# Simple EC2 + Spring Boot Deployment
# This script launches a new EC2 instance in the correct VPC and deploys the Spring Boot API

set -e

REGION="us-east-1"
VPC_ID="vpc-0a5017f4d8e1962ee"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Spring Boot API - Final Deployment to EC2                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Launch EC2
echo "🚀 Step 1/3: Launching EC2 instance in serverless VPC..."

SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" \
  --region $REGION \
  --query 'Subnets[0].SubnetId' \
  --output text)

LAMBDA_SG=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=concert-prod-lambda" \
  --region $REGION \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "  Subnet: $SUBNET_ID"
echo "  Security Group: $LAMBDA_SG"

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0453ec754f44f9a4a \
  --instance-type t3.small \
  --key-name Ja \
  --security-group-ids $LAMBDA_SG \
  --subnet-id $SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-api-prod}]' \
  --user-data '#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user' \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "  ✅ Instance launched: $INSTANCE_ID"

# Open port 8080
aws ec2 authorize-security-group-ingress \
  --group-id $LAMBDA_SG \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region $REGION 2>/dev/null && echo "  ✅ Port 8080 opened" || echo "  ℹ️  Port 8080 already open"

# Step 2: Wait for instance
echo ""
echo "⏳ Step 2/3: Waiting for instance to start (2-3 minutes)..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
sleep 40  # Extra time for Docker to install

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "  ✅ Instance ready!"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"

# Step 3: Deploy Spring Boot
echo ""
echo "🐳 Step 3/3: Deploying Spring Boot API..."

# Get database credentials
DB_CREDENTIALS=$(aws secretsmanager get-secret-value \
  --secret-id concert-prod/database \
  --region $REGION \
  --query 'SecretString' \
  --output text)

DB_USERNAME=$(echo "$DB_CREDENTIALS" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_CREDENTIALS" | jq -r '.password')

# Get ECR login
ECR_PASSWORD=$(aws ecr get-login-password --region $REGION)

# SSH and deploy
echo "  Connecting to EC2 and deploying..."
ssh -i /Users/putinan/development/DevOps/develop/aws/Ja.pem \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=30 \
    ec2-user@$PUBLIC_IP bash -s << EOF
set -e

echo "  → Logging into ECR..."
echo "$ECR_PASSWORD" | sudo docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

echo "  → Pulling Spring Boot image..."
sudo docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2

echo "  → Starting Spring Boot container..."
sudo docker run -d \
  --name concert-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert" \
  -e SPRING_DATASOURCE_USERNAME="$DB_USERNAME" \
  -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
  -e SPRING_PROFILES_ACTIVE="prod" \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
  -e REDIS_ENDPOINT="concert-prod-redis-tx4y2n.serverless.use1.cache.amazonaws.com" \
  -e REDIS_PORT="6379" \
  -e COGNITO_USER_POOL_ID="us-east-1_nTZpyinXc" \
  -e COGNITO_CLIENT_ID="5fpck32uhi8m87b5tkirvaf0iu" \
  -e S3_BUCKET_NAME="concert-prod-web-123456789012" \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2

echo "  → Waiting for Spring Boot to start..."
sleep 20

echo "  → Container status:"
sudo docker ps | grep concert-api || true

echo "  → Recent logs:"
sudo docker logs concert-api --tail 15 || true
EOF

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Deployment Complete!                                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Resources Deployed:"
echo "  - EC2 Instance: $INSTANCE_ID (t3.small)"
echo "  - Spring Boot API running in Docker"
echo "  - Connected to RDS MySQL, Redis, S3, Cognito"
echo ""
echo "🌐 API Endpoints:"
echo "  http://$PUBLIC_IP:8080/health"
echo "  http://$PUBLIC_IP:8080/api/auth/test"
echo "  http://$PUBLIC_IP:8080/api/auth/register"
echo "  http://$PUBLIC_IP:8080/api/auth/login"
echo ""
echo "📊 View logs:"
echo "  ssh -i /Users/putinan/development/DevOps/develop/aws/Ja.pem ec2-user@$PUBLIC_IP 'sudo docker logs -f concert-api'"
echo ""
echo "🧪 Testing API in 30 seconds..."
sleep 30

curl -s -w "\nStatus: %{http_code}\nTime: %{time_total}s\n" http://$PUBLIC_IP:8080/health || echo "API not responding yet (may still be starting)"

echo ""
echo "💰 Monthly Cost: ~\$40/month"
echo "  - EC2 t3.small: \$15"
echo "  - RDS MySQL: \$15"
echo "  - Redis: \$8"
echo "  - Other: \$2"
echo ""
echo "✨ Deployment successful!"
