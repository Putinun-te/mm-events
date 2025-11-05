#!/bin/bash
# 🔧 FIXED: EC2 now has ECR permissions!
# Wait 10 seconds for IAM permissions to propagate, then run this script in EC2 Instance Connect

echo "⏳ Waiting 10 seconds for IAM permissions to propagate..."
sleep 10

echo "🚀 Starting backend deployment..."

# Stop old containers
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Login to ECR (should work now with new permissions)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Pull latest image
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest

# Run backend
docker run -d -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_C \
  -e AWS_REGION=us-east-1 \
  -e AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012 \
  -e AWS_S3_USER_AVATARS_BUCKET=concert-user-avatars-useast1-123456789012 \
  -e AWS_COGNITO_USER_POOL_ID=us-east-1_nTZpyinXc \
  -e AWS_COGNITO_CLIENT_ID=5fpck32uhi8m87b5tkirvaf0iu \
  -e AWS_COGNITO_REGION=us-east-1 \
  --restart unless-stopped \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest

# Wait for startup
echo "⏳ Waiting 15 seconds for backend to start..."
sleep 15

# Check status
echo ""
echo "✅ Container Status:"
docker ps

echo ""
echo "📋 Application Logs (last 30 lines):"
docker logs $(docker ps -q) --tail 30

echo ""
echo "🎯 Backend should be available at: http://52.221.197.39:8080"
echo "Test with: curl http://52.221.197.39:8080/api/auth/test"
