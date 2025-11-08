#!/bin/bash
set -e

echo "🔨 Building backend JAR..."
cd main_backend
mvn clean package -DskipTests
cd ..

echo "📦 Copying JAR to EC2..."
scp -i concert-singapore.pem main_backend/target/concert-backend-1.0.0.jar ubuntu@13.250.108.116:/home/ubuntu/

echo "🔄 Restarting backend on EC2..."
ssh -i concert-singapore.pem ubuntu@13.250.108.116 << 'EOF'
docker stop concert-backend || true
docker rm concert-backend || true
docker run -d \
  --name concert-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
  -e SPRING_DATASOURCE_USERNAME=concert_user \
  -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_A \
  -e AWS_REGION=ap-southeast-1 \
  -e AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-singapore-123456789012 \
  -e AWS_S3_USER_AVATARS_BUCKET=concert-user-avatars-singapore-123456789012 \
  -e SPRING_DATA_REDIS_HOST=none \
  -e SPRING_AUTOCONFIGURE_EXCLUDE=org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration \
  -e CORS_ALLOWED_ORIGINS=https://d3jivuimmea02r.cloudfront.net \
  -v /home/ubuntu/concert-backend-1.0.0.jar:/app.jar \
  amazoncorretto:21-alpine \
  java -jar /app.jar
EOF

echo "✅ Backend redeployed successfully!"
echo "🔍 Checking logs..."
ssh -i concert-singapore.pem ubuntu@13.250.108.116 "docker logs --tail 50 concert-backend"
