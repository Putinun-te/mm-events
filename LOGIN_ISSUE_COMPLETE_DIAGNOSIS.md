# 🔴 LOGIN NOT WORKING - COMPLETE DIAGNOSIS & SOLUTION

**Date**: November 3, 2025  
**User Action Required**: YES - Backend needs to be started

---

## ✅ WHAT'S BEEN FIXED

### 1. Frontend `useApi` Composable ✅
- **Issue**: Missing composable that handles API calls
- **Fix**: Created `/app/composables/useApi.ts`
- **Result**: ✅ Frontend redeployed successfully
- **URL**: https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/

### 2. API Gateway Configuration ✅
- **Issue**: Pointing to placeholder URL `https://your-backend.example.com`
- **Fix**: Updated integration to `http://54.163.142.116:8080/api/{proxy}`
- **Result**: ✅ API Gateway now routing correctly

---

## ❌ WHAT'S NOT WORKING

### Backend Service NOT RUNNING

**Current Status**:
```
API Test: https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/test
Response: {"message":"Service Unavailable"}
HTTP Status: 503
```

**Problem**: The backend Java service on EC2 instance `54.163.142.116:8080` is not running.

**Evidence**:
- ✅ EC2 instance is running (`i-0580615ba39548431`)
- ✅ Instance has public IP (`54.163.142.116`)
- ✅ API Gateway can reach it (not timing out)
- ❌ Service at port 8080 is not responding
- ❌ Cannot verify via SSH (key pair issues)
- ❌ Cannot verify via SSM (instance not compatible)

---

## 🎯 SOLUTION

### What You Need to Do

The backend service needs to be manually started on the existing EC2 instance. Here are your options:

---

## 🔧 OPTION A: Using AWS Console (Easiest)

1. Go to **EC2 Dashboard** in AWS Console
2. Navigate to **Instances**
3. Find instance `concert-asg-instance` (ID: `i-0580615ba39548431`)
4. Click **Connect** button
5. Select **EC2 Instance Connect** tab
6. Click **Connect** (browser-based terminal will open)
7. Run these commands:

```bash
# Start the backend service
sudo systemctl start concert-backend

# Check it's running
sudo systemctl status concert-backend

# Start Docker MySQL if needed
sudo docker start concert-mysql 2>/dev/null || sudo docker run -d \
  --name concert-mysql \
  -e MYSQL_ROOT_PASSWORD=REDACTED_PASSWORD_B \
  -e MYSQL_DATABASE=concert \
  -p 3306:3306 \
  --restart unless-stopped \
  mysql:8.4.6

# Verify backend is accessible
curl http://localhost:8080/api/auth/test
```

---

## 🔧 OPTION B: Create New EC2 Instance with Backend

If the existing instance is corrupted, create a fresh one:

```bash
# First, create an IAM role and instance profile (one-time setup)
aws iam create-role \
  --role-name ConcertBackendRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || echo "Role already exists"

aws iam attach-role-policy \
  --role-name ConcertBackendRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore 2>/dev/null || echo "Already attached"

aws iam attach-role-policy \
  --role-name ConcertBackendRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess 2>/dev/null || echo "Already attached"

aws iam create-instance-profile \
  --instance-profile-name ConcertBackendProfile 2>/dev/null || echo "Profile already exists"

aws iam add-role-to-instance-profile \
  --instance-profile-name ConcertBackendProfile \
  --role-name ConcertBackendRole 2>/dev/null || echo "Role already added"

# Wait 10 seconds for IAM to propagate
sleep 10

# Then launch the instance with user data
# See OPTION C below for the full launch command
```

---

## 🔧 OPTION C: Full Automated Launch with User Data

```bash
#!/bin/bash

# Configuration
AWS_REGION="us-east-1"
INSTANCE_TYPE="t3.micro"
IMAGE_ID="ami-087126591972bfe96"
SECURITY_GROUP="sg-01d844b44878f2b16"
SUBNET="subnet-0cd8d035dcc0f09bb"

# User data script (will run on instance startup)
USER_DATA='#!/bin/bash
set -e

# Update and install dependencies
apt-get update -y
apt-get install -y openjdk-21-jre-headless docker.io curl awscli

# Start Docker
systemctl start docker
systemctl enable docker

# Setup MySQL
docker run -d \
  --name concert-mysql \
  -e MYSQL_ROOT_PASSWORD=REDACTED_PASSWORD_B \
  -e MYSQL_DATABASE=concert \
  -p 3306:3306 \
  --restart unless-stopped \
  mysql:8.4.6

sleep 10

# Setup backend
mkdir -p /opt/concert/logs
cd /opt/concert

# Download JAR from S3
aws s3 cp s3://concert-dev-frontend-142fee22/backend-deploy/concert-backend-1.0.0.jar . --region us-east-1

# Create systemd service
cat > /etc/systemd/system/concert-backend.service << '"'"'EOF'"'"'
[Unit]
Description=Concert Backend Service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/concert
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/concert"
Environment="SPRING_DATASOURCE_USERNAME=root"
Environment="SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_B"
ExecStart=/usr/bin/java -jar /opt/concert/concert-backend-1.0.0.jar
Restart=always
RestartSec=5
StandardOutput=append:/opt/concert/logs/app.log
StandardError=append:/opt/concert/logs/app.log

[Install]
WantedBy=multi-user.target
EOF

# Start backend
systemctl daemon-reload
systemctl enable concert-backend
systemctl start concert-backend

echo "✅ Backend started successfully"
'

# Base64 encode user data
USER_DATA_B64=$(echo "$USER_DATA" | base64 -w 0)

# Launch instance
echo "Launching new EC2 instance..."
RESPONSE=$(aws ec2 run-instances \
  --region $AWS_REGION \
  --image-id $IMAGE_ID \
  --instance-type $INSTANCE_TYPE \
  --security-group-ids $SECURITY_GROUP \
  --subnet-id $SUBNET \
  --iam-instance-profile Name=concert-backend-ec2-profile \
  --user-data "$USER_DATA_B64" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=concert-backend-fresh}]" \
  --output json)

INSTANCE_ID=$(echo $RESPONSE | jq -r '.Instances[0].InstanceId')
echo "✅ Instance launched: $INSTANCE_ID"
echo "⏳ Waiting for public IP..."

# Poll for public IP
for i in {1..60}; do
  PUBLIC_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null || echo "")
  
  if [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
    echo "✅ Instance ready!"
    echo ""
    echo "Instance Details:"
    echo "  ID: $INSTANCE_ID"
    echo "  IP: $PUBLIC_IP"
    echo ""
    echo "📋 Next: Update API Gateway integration to: http://$PUBLIC_IP:8080/api/{proxy}"
    echo "   Command:"
    echo "   aws apigatewayv2 update-integration --api-id t55pviree7 --region us-east-1 --integration-id lz9quj6 --integration-uri 'http://$PUBLIC_IP:8080/api/{proxy}'"
    echo ""
    echo "⏳ Wait 3-5 minutes for backend to start, then test:"
    echo "   curl https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/test"
    break
  fi
  
  echo "  Attempt $i/60..."
  sleep 2
done
```

---

## ✅ VERIFICATION STEPS

After starting the backend, test with:

```bash
# Test 1: Direct backend health
curl http://54.163.142.116:8080/api/auth/test

# Test 2: Through API Gateway
curl https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/test

# Expected response: "Auth API is working!"

# Test 3: Try login
curl -X POST https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"abc","password":"12345678"}'

# Expected response (if user exists):
# {"token":"REDACTED_JWT_TOKEN","username":"abc","email":"abc@example.com"}

# Expected response (if user doesn't exist):
# {"message":"Invalid username or password"}
```

---

## 📋 Login Flow (Corrected)

```
User visits: https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/
                          ↓
                   Login Form (Vue)
                          ↓
                  useApi composable ✅ FIXED
                          ↓
    Nuxt Server Route: POST /api/auth/login
                          ↓
    API Gateway: t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/login
                    ↓ (NOW ROUTING CORRECTLY ✅)
    Backend on EC2: http://54.163.142.116:8080/api/auth/login
                    ❌ NOT RESPONDING (NEEDS TO BE STARTED)
                          ↓
    Spring Boot AuthController.login()
                          ↓
    MySQL Database (Docker): localhost:3306
                          ↓
    Response: {token, username, email} or {message: error}
```

---

## 📝 Quick Checklist

- [x] Frontend `useApi` composable created
- [x] Frontend redeployed to S3
- [x] API Gateway updated to point to backend
- [x] Backend JAR available in S3
- [ ] **Backend service started on EC2** ← YOU ARE HERE
- [ ] Test endpoint responds
- [ ] Login works with valid credentials

---

## 🆘 If Nothing Works

1. **Check instance system logs**:
   ```bash
   aws ec2 get-console-output --instance-id i-0580615ba39548431 --region us-east-1
   ```

2. **Try new instance approach** (OPTION C above)

3. **Check security group**:
   ```bash
   aws ec2 describe-security-groups --group-ids sg-01d844b44878f2b16 --region us-east-1
   ```
   Should have inbound rule for port 8080 from anywhere (0.0.0.0/0)

4. **Verify S3 JAR exists**:
   ```bash
   aws s3 ls s3://concert-dev-frontend-142fee22/backend-deploy/
   ```

---

## 📊 Current System Status

| Component | Status | Details |
|-----------|--------|---------|
| Frontend | ✅ Working | Deployed to S3, `useApi` composable added |
| API Gateway | ✅ Working | Updated to point to `54.163.142.116:8080` |
| EC2 Instance | ✅ Running | `i-0580615ba39548431` at `54.163.142.116` |
| MySQL Docker | ❓ Unknown | Should be running on instance |
| Backend Service | ❌ Not Responding | Port 8080 not responding (503 Service Unavailable) |
| Backend JAR | ✅ Ready | Available in S3 |

---

## 🚀 IMMEDIATE NEXT STEP

**Choose one action**:

### Quick (< 5 minutes):
Use AWS Console → EC2 → Instance Connect → Start service

### Medium (5-10 minutes):
Run OPTION C automated launch script

### If stuck:
Run diagnostic to see console output

---

**Last Updated**: November 3, 2025 - 2:40 PM  
**Status**: 🟡 Partially Fixed - Waiting for backend service to start
