#!/bin/bash
# Automated EC2 Deployment for Spring Boot API
# Run from repo root: ./infra/deploy-ec2-automated.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
EC2_INSTANCE_ID="i-031914475e91af608"
REGION="us-east-1"
SSH_KEY="/Users/putinan/development/DevOps/develop/aws/concert-key.pem"
ECR_IMAGE="123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2"

echo -e "${GREEN}🚀 Starting EC2 Deployment...${NC}"

# Get EC2 public IP
echo -e "${YELLOW}📍 Getting EC2 instance information...${NC}"
EC2_IP=$(aws ec2 describe-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$EC2_IP" ] || [ "$EC2_IP" == "None" ]; then
    echo -e "${RED}❌ Could not get EC2 public IP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ EC2 IP: $EC2_IP${NC}"

# Get security group
SG_ID=$(aws ec2 describe-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$REGION" \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo -e "${YELLOW}🔒 Security Group: $SG_ID${NC}"

# Ensure port 8080 is open
echo -e "${YELLOW}🔓 Ensuring port 8080 is open...${NC}"
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region "$REGION" 2>/dev/null && echo -e "${GREEN}✅ Port 8080 opened${NC}" || echo -e "${YELLOW}⚠️  Port 8080 already open${NC}"

# Get database credentials
echo -e "${YELLOW}🔐 Retrieving database credentials...${NC}"
DB_CREDENTIALS=$(aws secretsmanager get-secret-value \
  --secret-id concert-prod/database \
  --region "$REGION" \
  --query 'SecretString' \
  --output text)

DB_USERNAME=$(echo "$DB_CREDENTIALS" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_CREDENTIALS" | jq -r '.password')

echo -e "${GREEN}✅ Credentials retrieved${NC}"

# Get ECR login password
echo -e "${YELLOW}🔑 Getting ECR login token...${NC}"
ECR_PASSWORD=$(aws ecr get-login-password --region "$REGION")
echo -e "${GREEN}✅ ECR token retrieved${NC}"

# Create deployment commands
DEPLOY_COMMANDS=$(cat << 'SCRIPT'
#!/bin/bash
set -e

echo "=== Installing Docker ==="
if ! command -v docker &> /dev/null; then
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    echo "Docker installed successfully"
else
    echo "Docker already installed"
    sudo systemctl start docker || true
fi

echo "=== Logging into ECR ==="
# Get ECR login token from local machine and use it
ECR_PASSWORD="REPLACE_ECR_PASSWORD"
echo "$ECR_PASSWORD" | sudo docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

echo "=== Stopping existing container ==="
sudo docker stop concert-api 2>/dev/null || echo "No existing container to stop"
sudo docker rm concert-api 2>/dev/null || echo "No existing container to remove"

echo "=== Pulling latest image ==="
sudo docker pull REPLACE_ECR_IMAGE

echo "=== Starting new container ==="
sudo docker run -d \
  --name concert-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert" \
  -e SPRING_DATASOURCE_USERNAME="REPLACE_DB_USERNAME" \
  -e SPRING_DATASOURCE_PASSWORD="REPLACE_DB_PASSWORD" \
  -e SPRING_PROFILES_ACTIVE="prod" \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
  -e REDIS_ENDPOINT="concert-prod-redis-tx4y2n.serverless.use1.cache.amazonaws.com" \
  -e REDIS_PORT="6379" \
  -e COGNITO_USER_POOL_ID="us-east-1_nTZpyinXc" \
  -e COGNITO_CLIENT_ID="5fpck32uhi8m87b5tkirvaf0iu" \
  -e S3_BUCKET_NAME="concert-prod-web-123456789012" \
  REPLACE_ECR_IMAGE

echo "=== Waiting for container to start ==="
sleep 15

echo "=== Container status ==="
sudo docker ps | grep concert-api || echo "WARNING: Container may not be running"

echo "=== Recent logs ==="
sudo docker logs concert-api --tail 30 || true

echo "=== Deployment complete ==="
SCRIPT
)

# Replace placeholders
DEPLOY_COMMANDS="${DEPLOY_COMMANDS//REPLACE_ECR_IMAGE/$ECR_IMAGE}"
DEPLOY_COMMANDS="${DEPLOY_COMMANDS//REPLACE_DB_USERNAME/$DB_USERNAME}"
DEPLOY_COMMANDS="${DEPLOY_COMMANDS//REPLACE_DB_PASSWORD/$DB_PASSWORD}"
DEPLOY_COMMANDS="${DEPLOY_COMMANDS//REPLACE_ECR_PASSWORD/$ECR_PASSWORD}"

# Execute deployment on EC2
echo -e "${YELLOW}📤 Deploying to EC2 instance...${NC}"
ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    ec2-user@$EC2_IP << EOF
$DEPLOY_COMMANDS
EOF

echo ""
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo -e "${GREEN}🌐 API Endpoint: http://$EC2_IP:8080${NC}"
echo -e "${GREEN}🏥 Health Check: http://$EC2_IP:8080/health${NC}"
echo ""
echo "Waiting 10 seconds for Spring Boot to start..."
sleep 10

# Test the endpoint
echo ""
echo -e "${YELLOW}🧪 Testing API...${NC}"
if curl -s -f -m 10 "http://$EC2_IP:8080/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is UP!${NC}"
    curl -s "http://$EC2_IP:8080/health" | jq '.' || curl -s "http://$EC2_IP:8080/health"
else
    echo -e "${YELLOW}⚠️  API not responding yet (may still be starting)${NC}"
    echo "Check logs with:"
    echo "  ssh -i $SSH_KEY ec2-user@$EC2_IP 'sudo docker logs concert-api'"
fi

echo ""
echo -e "${GREEN}📝 Test commands:${NC}"
echo "  curl http://$EC2_IP:8080/health"
echo "  curl http://$EC2_IP:8080/api/auth/test"
echo ""
echo -e "${GREEN}📊 View logs:${NC}"
echo "  ssh -i $SSH_KEY ec2-user@$EC2_IP 'sudo docker logs -f concert-api'"
