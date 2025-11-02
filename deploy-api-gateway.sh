#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Concert Application API Gateway Deployment ===${NC}"

# Configuration - UPDATE THESE VALUES
EC2_USER="ec2-user"
EC2_HOST="${1:-}"  # Pass as first argument, e.g., ./deploy-api-gateway.sh ec2-44-211-15-23.compute-1.amazonaws.com
PEM_KEY="${2:-~/keys/concert-backend.pem}"  # Pass as second argument or update the default
API_GATEWAY_URL="https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod"
CORS_ORIGINS="https://t55pviree7.execute-api.us-east-1.amazonaws.com,https://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com"
S3_FRONTEND_BUCKET="concert-dev-frontend-142fee22"

# Validate inputs
if [ -z "$EC2_HOST" ]; then
  echo -e "${RED}ERROR: EC2 host not provided.${NC}"
  echo "Usage: ./deploy-api-gateway.sh <EC2_HOST> [PEM_KEY]"
  echo "Example: ./deploy-api-gateway.sh ec2-44-211-15-23.compute-1.amazonaws.com ~/keys/concert-backend.pem"
  exit 1
fi

if [ ! -f "$PEM_KEY" ]; then
  echo -e "${RED}ERROR: PEM key not found at $PEM_KEY${NC}"
  exit 1
fi

echo -e "${GREEN}Configuration:${NC}"
echo "  EC2 Host: $EC2_HOST"
echo "  PEM Key: $PEM_KEY"
echo "  API Gateway URL: $API_GATEWAY_URL"
echo "  CORS Origins: $CORS_ORIGINS"
echo "  S3 Frontend Bucket: $S3_FRONTEND_BUCKET"
echo ""

# Step 1: Build Backend JAR
echo -e "${YELLOW}Step 1: Building Spring Boot backend...${NC}"
cd main_backend
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn clean package -DskipTests
if [ ! -f "target/concert-backend-1.0.0.jar" ]; then
  echo -e "${RED}ERROR: Backend build failed - JAR not found${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Backend JAR built successfully${NC}"
cd ..

# Step 2: Deploy Backend JAR to EC2
echo -e "${YELLOW}Step 2: Deploying backend JAR to EC2...${NC}"
chmod 400 "$PEM_KEY"
scp -i "$PEM_KEY" \
  -o "StrictHostKeyChecking=no" \
  -o "UserKnownHostsFile=/dev/null" \
  main_backend/target/concert-backend-1.0.0.jar \
  "${EC2_USER}@${EC2_HOST}:/tmp/concert-backend-1.0.0.jar"
echo -e "${GREEN}✓ Backend JAR copied to EC2${NC}"

# Step 3: Restart Backend Service
echo -e "${YELLOW}Step 3: Restarting backend service with API Gateway config...${NC}"
ssh -i "$PEM_KEY" \
  -o "StrictHostKeyChecking=no" \
  -o "UserKnownHostsFile=/dev/null" \
  "${EC2_USER}@${EC2_HOST}" <<'EOFREMOTE'
set -e
echo "Stopping existing service..."
sudo systemctl stop concert-backend || true
sleep 2

echo "Copying new JAR..."
sudo cp /tmp/concert-backend-1.0.0.jar /opt/concert/concert-backend-1.0.0.jar
sudo chown ec2-user:ec2-user /opt/concert/concert-backend-1.0.0.jar

echo "Starting service with updated CORS configuration..."
export APP_CORS_ALLOWED_ORIGINS="https://t55pviree7.execute-api.us-east-1.amazonaws.com,https://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com"
sudo -E systemctl start concert-backend

sleep 3
systemctl status concert-backend || true
EOFREMOTE
echo -e "${GREEN}✓ Backend service restarted${NC}"

# Step 4: Build Frontend
echo -e "${YELLOW}Step 4: Building Nuxt frontend with API Gateway URL...${NC}"
cd main_frontend/concert1
export API_GATEWAY_URL="$API_GATEWAY_URL"
npm install 2>&1 | tail -5
npm run build 2>&1 | tail -10
if [ ! -d ".output/public" ]; then
  echo -e "${RED}ERROR: Frontend build failed - .output/public not found${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Frontend built successfully${NC}"

# Step 5: Deploy Frontend to S3
echo -e "${YELLOW}Step 5: Deploying frontend to S3...${NC}"
aws s3 sync .output/public s3://"$S3_FRONTEND_BUCKET" --delete --region us-east-1
echo -e "${GREEN}✓ Frontend deployed to S3${NC}"
cd ../..

# Step 6: Smoke Test
echo -e "${YELLOW}Step 6: Running smoke test...${NC}"
echo "Testing API Gateway endpoint..."
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" "$API_GATEWAY_URL/api/events")
if [ "$API_TEST" = "200" ] || [ "$API_TEST" = "401" ] || [ "$API_TEST" = "403" ]; then
  echo -e "${GREEN}✓ API Gateway responding (HTTP $API_TEST)${NC}"
else
  echo -e "${YELLOW}⚠ API Gateway returned HTTP $API_TEST (expected 200/401/403)${NC}"
fi

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo -e "${GREEN}Frontend URL: https://${S3_FRONTEND_BUCKET}.s3-website-us-east-1.amazonaws.com${NC}"
echo -e "${GREEN}API Gateway URL: ${API_GATEWAY_URL}${NC}"
echo ""
echo "Next steps:"
echo "1. Visit the frontend URL and test event creation with an image"
echo "2. Check CloudWatch logs if anything fails: /aws/apigateway/concert-prod-http"
echo "3. Monitor backend: ssh -i $PEM_KEY ${EC2_USER}@${EC2_HOST} 'tail -f /var/log/concert/application.log'"
