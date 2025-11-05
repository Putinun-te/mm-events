#!/bin/bash
# EC2 Backend Deployment Script with CORS Fix
# Save this as deploy.sh on EC2 and run: bash deploy.sh

echo "🔄 Pulling latest code..."
cd /home/ubuntu
git clone https://github.com/MorningMores/develop.git concert-cors 2>/dev/null || (cd concert-cors && git pull origin release/v1.0.0)

echo "📦 Building JAR..."
cd concert-cors/main_backend
chmod +x mvnw
./mvnw clean package -DskipTests

echo "🛑 Stopping old backend..."
docker stop $(docker ps -q) 2>/dev/null
pkill -f concert-backend 2>/dev/null

echo "🚀 Starting new backend with CORS fix..."
# Using environment variables to avoid special character issues
export DB_URL="jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert"
export DB_USER="admin"
export DB_PASS="REDACTED_PASSWORD_C"
export COGNITO_POOL="us-east-1_nTZpyinXc"
export COGNITO_CLIENT="5fpck32uhi8m87b5tkirvaf0iu"
export COGNITO_REGION="us-east-1"

nohup java -jar target/concert-backend-1.0.0.jar \
  --spring.datasource.url="$DB_URL" \
  --spring.datasource.username="$DB_USER" \
  --spring.datasource.password="$DB_PASS" \
  --aws.cognito.user-pool-id="$COGNITO_POOL" \
  --aws.cognito.client-id="$COGNITO_CLIENT" \
  --aws.cognito.region="$COGNITO_REGION" \
  > /home/ubuntu/backend.log 2>&1 &

echo "⏳ Waiting 20 seconds for startup..."
sleep 20

echo "🧪 Testing backend..."
curl http://localhost:8080/api/auth/test

echo ""
echo "✅ Deployment complete!"
echo "📝 Check logs: tail -f /home/ubuntu/backend.log"
