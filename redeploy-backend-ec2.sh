#!/bin/bash
# Redeploy backend with fresh Docker image on EC2

cat << 'EOF'
# Run these commands in EC2 Instance Connect terminal:

# 1. Stop and remove old container
docker stop concert-backend
docker rm concert-backend

# 2. Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# 3. Pull latest image
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest

# 4. Run new container with environment variables
docker run -d \
  --name concert-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert" \
  -e SPRING_DATASOURCE_USERNAME="admin" \
  -e SPRING_DATASOURCE_PASSWORD="REDACTED_PASSWORD_C" \
  -e AWS_COGNITO_USER_POOL_ID="us-east-1_nTZpyinXc" \
  -e AWS_COGNITO_CLIENT_ID="5fpck32uhi8m87b5tkirvaf0iu" \
  -e AWS_COGNITO_REGION="us-east-1" \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest

# 5. Wait for startup (30 seconds)
sleep 30

# 6. Check logs for "Started ConcertBackendApplication"
docker logs concert-backend --tail 50

# 7. Test the API
curl http://localhost:8080/api/auth/test

EOF
