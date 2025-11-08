#!/bin/bash
set -e

INSTANCE_IP="52.221.191.211"
KEY_FILE="JA.pem"
RDS_ENDPOINT="concert-prod-db.c8aqvqzqxqxq.ap-southeast-1.rds.amazonaws.com"

echo "🚀 Deploying backend to Singapore..."

# Copy JAR
echo "📤 Uploading JAR..."
scp -o StrictHostKeyChecking=no -i $KEY_FILE main_backend/target/concert-backend-1.0.0.jar ec2-user@$INSTANCE_IP:~/

# Deploy
echo "🐳 Starting Docker container..."
ssh -o StrictHostKeyChecking=no -i $KEY_FILE ec2-user@$INSTANCE_IP << 'EOF'
docker stop concert-backend 2>/dev/null || true
docker rm concert-backend 2>/dev/null || true

docker run -d \
  --name concert-backend \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.c8aqvqzqxqxq.ap-southeast-1.rds.amazonaws.com:3306/concert_db" \
  -e SPRING_DATASOURCE_USERNAME="concert_user" \
  -e SPRING_DATASOURCE_PASSWORD="REDACTED_PASSWORD_A" \
  -e AWS_REGION="ap-southeast-1" \
  -v ~/concert-backend-1.0.0.jar:/app/app.jar \
  eclipse-temurin:21-jre \
  java -jar /app/app.jar
EOF

echo "✅ Deployed! Test: curl http://$INSTANCE_IP:8080/actuator/health"
