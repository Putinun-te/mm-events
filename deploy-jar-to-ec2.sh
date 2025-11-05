#!/bin/bash

# Deploy JAR directly to EC2 and restart backend
# This is faster than Docker build when making small changes like CORS

echo "📦 Copying JAR to EC2..."
scp -i ~/.ssh/concert-prod-key.pem \
  /Users/putinan/development/DevOps/develop/main_backend/target/concert-backend-1.0.0.jar \
  ubuntu@52.221.197.39:/home/ubuntu/

echo ""
echo "🚀 Deploying on EC2..."
ssh -i ~/.ssh/concert-prod-key.pem ubuntu@52.221.197.39 << 'EOF'
# Stop existing backend
docker stop $(docker ps -q --filter ancestor=123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest) 2>/dev/null || true

# Run JAR directly (faster than Docker rebuild)
pkill -f concert-backend || true
nohup java -jar /home/ubuntu/concert-backend-1.0.0.jar \
  --spring.datasource.url=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert \
  --spring.datasource.username=admin \
  --spring.datasource.password=REDACTED_PASSWORD_C \
  --aws.cognito.user-pool-id=us-east-1_nTZpyinXc \
  --aws.cognito.client-id=5fpck32uhi8m87b5tkirvaf0iu \
  --aws.cognito.region=us-east-1 \
  > /home/ubuntu/backend.log 2>&1 &

# Wait for startup
sleep 15

# Check if running
if curl -s http://localhost:8080/api/auth/test | grep -q "working"; then
  echo "✅ Backend deployed successfully!"
  echo "📝 Logs at: /home/ubuntu/backend.log"
else
  echo "❌ Backend deployment failed. Check logs:"
  tail -50 /home/ubuntu/backend.log
fi
EOF

echo ""
echo "Testing from outside..."
sleep 2
curl http://52.221.197.39:8080/api/auth/test
