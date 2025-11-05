# 🚀 Quick CORS Fix Deployment

## Problem
Frontend at `https://d3jivuimmea02r.cloudfront.net` is blocked by CORS because backend only allows old domains.

## Solution
Added CloudFront domains to CORS configuration in `SecurityConfig.java`.

## Deploy on EC2 Instance Connect

Open: https://ap-southeast-1.console.aws.amazon.com/ec2/home?region=ap-southeast-1#ConnectToInstance:instanceId=i-0ffd487469a6fa1aa

Paste these commands:

```bash
# Pull latest code with CORS fix
cd /home/ubuntu
git clone https://github.com/MorningMores/develop.git concert-backend-cors || (cd concert-backend-cors && git pull)
cd concert-backend-cors/main_backend

# Build JAR
./mvnw clean package -DskipTests

# Stop old backend
docker stop $(docker ps -q) 2>/dev/null || true
pkill -f concert-backend || true

# Run new backend with CORS fix
nohup java -jar target/concert-backend-1.0.0.jar \
  --spring.datasource.url=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert \
  --spring.datasource.username=admin \
  --spring.datasource.password=REDACTED_PASSWORD_C \
  --aws.cognito.user-pool-id=us-east-1_nTZpyinXc \
  --aws.cognito.client-id=5fpck32uhi8m87b5tkirvaf0iu \
  --aws.cognito.region=us-east-1 \
  > backend.log 2>&1 &

# Wait for startup (15 seconds)
echo "⏳ Waiting for backend to start..."
sleep 15

# Test
curl http://localhost:8080/api/auth/test
```

## Expected Output
```
Auth API is working!
```

## Then Test Frontend
1. Go to https://d3jivuimmea02r.cloudfront.net/RegisterPage
2. Try to register a new user
3. Should work without "Failed to fetch" error

## What Changed
Added these domains to CORS allowed origins:
- ✅ https://d3jivuimmea02r.cloudfront.net (Web CloudFront)
- ✅ https://dzh397ixo71bk.cloudfront.net (Images CloudFront)
- ✅ http://concert-prod-web-123456789012.s3-website-us-east-1.amazonaws.com (S3 Web)
- ✅ https://concert-prod-web-123456789012.s3-website-us-east-1.amazonaws.com (S3 Web HTTPS)
