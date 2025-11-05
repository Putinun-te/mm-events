#!/bin/bash
# EC2 Backend Deployment Script with CORS Fix
# Save this as deploy.sh on EC2 and run: bash deploy.sh

set -e  # Exit on error

echo "🔍 Checking Java installation..."
if ! command -v java &> /dev/null; then
    echo "❌ Java not found! Installing Amazon Corretto 21..."
    # Amazon Linux uses yum, not apt
    sudo yum install -y java-21-amazon-corretto-devel
fi
java -version

echo "�🔄 Pulling latest code..."
cd /home/ubuntu
if [ ! -d "concert-cors" ]; then
    git clone https://github.com/MorningMores/develop.git concert-cors
    cd concert-cors
    git checkout release/v1.0.0
else
    cd concert-cors
    git fetch origin
    git checkout release/v1.0.0
    git pull origin release/v1.0.0
fi

echo "📦 Building JAR..."
cd main_backend
chmod +x mvnw
./mvnw clean package -DskipTests

if [ ! -f "target/concert-backend-1.0.0.jar" ]; then
    echo "❌ Build failed! JAR not found."
    exit 1
fi

echo "🛑 Stopping old backend..."
docker stop $(docker ps -q) 2>/dev/null || true
pkill -9 -f "concert-backend" || true
sleep 2

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

BACKEND_PID=$!
echo "Backend started with PID: $BACKEND_PID"

echo "⏳ Waiting 25 seconds for startup..."
sleep 25

echo "🧪 Testing backend..."
if curl -f http://localhost:8080/api/auth/test 2>/dev/null; then
    echo ""
    echo "✅ Deployment successful!"
else
    echo ""
    echo "❌ Backend not responding. Checking logs:"
    tail -50 /home/ubuntu/backend.log
    exit 1
fi

echo "📝 Check logs anytime: tail -f /home/ubuntu/backend.log"
