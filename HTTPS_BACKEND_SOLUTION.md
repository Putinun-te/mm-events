# HTTPS Backend Solution

## Problem
Frontend served over HTTPS cannot call HTTP backend due to browser mixed content blocking.

## Solution Implemented
Created API Gateway HTTP API as HTTPS proxy to backend.

### API Gateway Details
- **API ID**: t4elolxqp8
- **HTTPS Endpoint**: https://t4elolxqp8.execute-api.ap-southeast-1.amazonaws.com
- **Region**: ap-southeast-1

## Steps to Complete

### 1. Fix Backend Database Connection
The backend is failing to start due to incorrect database credentials.

**Current Error**: `Access denied for user 'admin'@'172.31.30.48' (using password: YES)`

**Solution**: Deploy backend with correct RDS password:

```bash
aws ssm send-command \
  --instance-ids "i-0ffd487469a6fa1aa" \
  --document-name "AWS-RunShellScript" \
  --region ap-southeast-1 \
  --parameters 'commands=[
    "docker stop $(docker ps -q) 2>/dev/null || true",
    "docker rm $(docker ps -aq) 2>/dev/null || true", 
    "docker run -d -p 8080:8080 \
      -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
      -e SPRING_DATASOURCE_USERNAME=admin \
      -e SPRING_DATASOURCE_PASSWORD=YOUR_CORRECT_PASSWORD \
      -e AWS_REGION=us-east-1 \
      -e AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012 \
      -e AWS_S3_USER_AVATARS_BUCKET=concert-user-avatars-useast1-123456789012 \
      -e AWS_COGNITO_USER_POOL_ID=us-east-1_nTZpyinXc \
      -e AWS_COGNITO_CLIENT_ID=5fpck32uhi8m87b5tkirvaf0iu \
      -e AWS_COGNITO_REGION=us-east-1 \
      --restart unless-stopped \
      123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:cors-fix"
  ]' \
  --output text
```

### 2. Update Frontend Configuration

Update `main_frontend/concert1/.env`:
```bash
BACKEND_BASE_URL=https://t4elolxqp8.execute-api.ap-southeast-1.amazonaws.com
```

### 3. Rebuild and Deploy Frontend

```bash
cd main_frontend/concert1
npm run build
aws s3 sync .output/public/ s3://YOUR_FRONTEND_BUCKET/ --delete
```

### 4. Test the HTTPS Backend

```bash
# Test endpoint
curl https://t4elolxqp8.execute-api.ap-southeast-1.amazonaws.com/api/auth/test

# Test registration
curl -X POST https://t4elolxqp8.execute-api.ap-southeast-1.amazonaws.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

## What Was Fixed

1. ✅ Added CORS configuration to SecurityConfig.java
2. ✅ Created API Gateway HTTP API as HTTPS proxy
3. ✅ Configured proxy integration to backend EC2
4. ⏳ Need to fix database credentials and restart backend
5. ⏳ Need to update frontend to use HTTPS API Gateway URL

## Architecture

```
Frontend (HTTPS) → API Gateway (HTTPS) → EC2 Backend (HTTP:8080) → RDS MySQL
```

This solves the mixed content issue while keeping the backend on HTTP internally.