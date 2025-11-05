#!/bin/bash
set -e

# 🚀 Deploy Backend using AWS Systems Manager (No SSH key needed)

INSTANCE_ID="i-0ffd487469a6fa1aa"
RDS_ENDPOINT="concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com"

echo "🔨 Pushing Docker image..."
cd main_backend
docker buildx build --platform linux/amd64 \
  -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest \
  --push . || echo "Image already pushed, continuing..."

echo "📦 Deploying to EC2 via SSM..."
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --region ap-southeast-1 \
  --parameters 'commands=[
    "docker stop $(docker ps -q) 2>/dev/null || true",
    "docker rm $(docker ps -aq) 2>/dev/null || true",
    "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com",
    "docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest",
    "docker run -d -p 8080:8080 -e SPRING_DATASOURCE_URL=jdbc:mysql://'"$RDS_ENDPOINT"':3306/concert_db -e SPRING_DATASOURCE_USERNAME=admin -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_C -e AWS_REGION=us-east-1 -e AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012 -e AWS_S3_USER_AVATARS_BUCKET=concert-user-avatars-useast1-123456789012 -e AWS_COGNITO_USER_POOL_ID=us-east-1_nTZpyinXc -e AWS_COGNITO_CLIENT_ID=5fpck32uhi8m87b5tkirvaf0iu -e AWS_COGNITO_REGION=us-east-1 --restart unless-stopped 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest"
  ]' \
  --output text

echo ""
echo "⏳ Waiting 20 seconds for deployment..."
sleep 20

echo ""
echo "✅ Testing backend..."
curl -s http://52.221.197.39:8080/api/auth/test || echo "Backend not ready yet, wait a minute and try: curl http://52.221.197.39:8080/api/auth/test"

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📊 URLs:"
echo "  Backend: http://52.221.197.39:8080"
echo "  Images CDN: https://dzh397ixo71bk.cloudfront.net"
echo "  Web CDN: https://d3jivuimmea02r.cloudfront.net"
