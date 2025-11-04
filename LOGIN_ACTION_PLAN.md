# 🎯 LOGIN FIX - ACTION PLAN

**Status**: 60% Fixed (Frontend works, Backend needs to start)

---

## ✅ WHAT'S ALREADY DONE

1. ✅ Created `useApi` composable (was missing)
2. ✅ Updated API Gateway URL (was pointing to fake domain)
3. ✅ Rebuilt and redeployed frontend to S3
4. ✅ Verified all infrastructure is in place

---

## ❌ WHAT'S NOT DONE

**Backend service is not running** - This is why login returns 503 error

---

## 🚀 HOW TO FIX (Pick ONE option)

### OPTION 1: AWS Console (Fastest - 2 minutes) ⭐ RECOMMENDED

This is the fastest option for a quick test.

1. Open AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:

2. Look for instance named: **`concert-asg-instance`**
   - ID: `i-0580615ba39548431`
   - Public IP: `54.163.142.116`

3. Click on the instance name

4. Click **"Connect"** button (top right of screen)

5. Click the **"EC2 Instance Connect"** tab

6. Click **"Connect"** (a browser-based terminal will open)

7. Copy and paste these commands:

```bash
sudo systemctl start concert-backend
sleep 5
sudo docker ps -a | grep concert
curl http://localhost:8080/api/auth/test
```

8. You should see output showing:
   - Service starting
   - Docker MySQL running
   - "Auth API is working!" response

9. **DONE!** Backend is now running. Try logging in at:
   https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/

---

### OPTION 2: AWS Console Commands

If EC2 Instance Connect doesn't work, use SSM:

```bash
aws ssm send-command \
  --region us-east-1 \
  --instance-ids i-0580615ba39548431 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo systemctl start concert-backend","sleep 5","curl http://localhost:8080/api/auth/test"]'

# Then check the output:
aws ssm get-command-invocation \
  --region us-east-1 \
  --command-id <COMMAND_ID> \
  --instance-id i-0580615ba39548431 \
  --query 'StandardOutputContent'
```

---

### OPTION 3: Launch Fresh Instance (5-10 minutes)

If the existing instance is corrupted, create a new one:

First, setup IAM role (one-time):

```bash
# Create IAM role
aws iam create-role \
  --role-name ConcertBackendLaunchRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || echo "Role exists"

# Attach policies
aws iam attach-role-policy \
  --role-name ConcertBackendLaunchRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

aws iam attach-role-policy \
  --role-name ConcertBackendLaunchRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name ConcertBackendLaunchProfile 2>/dev/null || echo "Profile exists"

aws iam add-role-to-instance-profile \
  --instance-profile-name ConcertBackendLaunchProfile \
  --role-name ConcertBackendLaunchRole 2>/dev/null || echo "Role added"

# Wait for IAM to propagate
sleep 15
```

Then launch instance:

```bash
# Create launch script with backend setup
cat > /tmp/start-backend.sh << 'EOF'
#!/bin/bash
set -e

# Install dependencies
apt-get update -y
apt-get install -y openjdk-21-jre-headless docker.io awscli

# Start Docker
systemctl start docker
systemctl enable docker

# Start MySQL
docker run -d \
  --name concert-mysql \
  -e MYSQL_ROOT_PASSWORD=REDACTED_PASSWORD_B \
  -e MYSQL_DATABASE=concert \
  -p 3306:3306 \
  --restart unless-stopped \
  mysql:8.4.6

# Wait for MySQL
sleep 15

# Setup backend directory
mkdir -p /opt/concert/logs
cd /opt/concert

# Download JAR
aws s3 cp s3://concert-dev-frontend-142fee22/backend-deploy/concert-backend-1.0.0.jar . --region us-east-1

# Create systemd service
cat > /etc/systemd/system/concert-backend.service << 'SERVICE'
[Unit]
Description=Concert Backend Service
After=docker.service

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
SERVICE

# Start backend
systemctl daemon-reload
systemctl enable concert-backend
systemctl start concert-backend

echo "✅ Backend ready!"
EOF

# Encode user data
USER_DATA=$(base64 -w 0 < /tmp/start-backend.sh)

# Launch instance
RESPONSE=$(aws ec2 run-instances \
  --region us-east-1 \
  --image-id ami-087126591972bfe96 \
  --instance-type t3.micro \
  --security-group-ids sg-01d844b44878f2b16 \
  --subnet-id subnet-0cd8d035dcc0f09bb \
  --iam-instance-profile Name=ConcertBackendLaunchProfile \
  --user-data "$USER_DATA" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=concert-backend-new}]" \
  --output json)

INSTANCE_ID=$(echo $RESPONSE | jq -r '.Instances[0].InstanceId')
echo "✅ Instance launched: $INSTANCE_ID"
echo "⏳ Waiting for public IP..."

# Wait for IP
for i in {1..60}; do
  PUBLIC_IP=$(aws ec2 describe-instances \
    --region us-east-1 \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null || echo "")
  
  if [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
    echo "✅ New instance running at: $PUBLIC_IP"
    echo ""
    echo "📌 Update API Gateway:"
    echo "aws apigatewayv2 update-integration --api-id t55pviree7 --region us-east-1 --integration-id lz9quj6 --integration-uri 'http://$PUBLIC_IP:8080/api/{proxy}'"
    echo ""
    echo "⏳ Wait 3-5 minutes for backend to start, then test:"
    echo "curl https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/test"
    break
  fi
  
  echo "   Attempt $i/60..."
  sleep 2
done
```

---

## ✅ VERIFICATION

After starting backend, test with these commands:

```bash
# Test 1: Backend health
curl https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/test

# Should return: "Auth API is working!"

# Test 2: Try login
curl -X POST https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"abc","password":"12345678"}'

# Should return either:
# {"token":"...","username":"abc","email":"..."}  (if user exists)
# or
# {"message":"Invalid username or password"}  (if user doesn't exist)
```

---

## 🧪 MANUAL TEST

Try logging in at: https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/

Use credentials:
- **Email/Username**: abc
- **Password**: 12345678

Expected:
- ✅ Should show success message
- ✅ Should redirect to home or account page
- ✅ Token should be saved to browser localStorage

---

## 📊 SUMMARY OF FIXES

| Issue | Status | Solution |
|-------|--------|----------|
| useApi composable missing | ✅ FIXED | Created `/app/composables/useApi.ts` |
| API Gateway wrong URL | ✅ FIXED | Updated to `54.163.142.116:8080` |
| Frontend not updated | ✅ FIXED | Rebuilt and redeployed to S3 |
| Backend not running | ❌ ACTION NEEDED | Start service using Option 1, 2, or 3 |

---

## 🎯 YOUR NEXT ACTION

**Choose one:**

1. **Fast** (2 min): Open EC2 console → Instance Connect → Start service
2. **Medium** (5 min): Use AWS SSM command
3. **Clean** (10 min): Launch fresh instance

**Then test**: curl the health endpoint or try logging in

---

## 📞 TROUBLESHOOTING

If health check still returns 503 after 5 minutes:

```bash
# SSH to instance (if you have key)
ssh -i path/to/concert-key.pem ubuntu@54.163.142.116

# Check service status
sudo systemctl status concert-backend

# Check logs
sudo journalctl -u concert-backend -n 50

# Check if MySQL is running
sudo docker ps | grep concert-mysql

# Try manual start
sudo systemctl start concert-backend
sleep 5
sudo systemctl status concert-backend

# Check if port 8080 is listening
sudo netstat -tlnp | grep 8080
```

---

## 📝 REFERENCE INFO

- **Frontend URL**: https://concert-dev-frontend-142fee22.s3.us-east-1.amazonaws.com/
- **API Gateway**: https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod
- **Backend IP**: 54.163.142.116:8080
- **EC2 Instance ID**: i-0580615ba39548431
- **Database**: Docker MySQL at localhost:3306
- **Credentials**: root / REDACTED_PASSWORD_B

---

**Start with OPTION 1 (AWS Console)** - it's the quickest! 🚀
