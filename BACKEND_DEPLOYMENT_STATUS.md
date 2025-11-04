# Concert Platform - Backend Deployment Status & Recovery Guide

**Status**: ⚠️ Backend deployment blocked by infrastructure connectivity issues

---

## Current Infrastructure State

### ✅ Completed
- Frontend: Deployed to S3 and accessible via REST endpoint
- API Gateway: Configured and routing requests
- MySQL: Upgraded to 8.4.6 on RDS
- Backend Code: Updated with environment variable configuration
- Backend JAR: Rebuilt and uploaded to S3

### ❌ Issues
- Old EC2 instance (i-02883ae4914a92e3e): **TERMINATED**
- SSH connectivity: Consistently timing out during banner exchange
- Database routing: VPC isolation between EC2 and RDS

### 📍 Current Running Resources
- ASG Instance: `i-0580615ba39548431` at `54.163.142.116` (t3.micro, running)
- Frontend S3: `concert-dev-frontend-142fee22`
- API Gateway: `t55pviree7.execute-api.us-east-1.amazonaws.com`

---

## Root Cause Analysis

1. **VPC Isolation**: EC2 in `vpc-077128945cf424869`, RDS in `vpc-06a5572e8d62bc9e7`
2. **Connection Failure**: Backend tries to connect to RDS, times out
3. **Workaround Implemented**: Docker MySQL 8.4.6 running locally on EC2
4. **Access Blockage**: SSH daemon not responding (banner exchange timeout)

---

## Solution Implemented

### Code Changes
File: `main_backend/src/main/resources/application.properties`

**Before:**
```properties
spring.datasource.url=jdbc:mysql://localhost:3306/devop_db
```

**After:**
```properties
spring.datasource.url=${SPRING_DATASOURCE_URL:jdbc:mysql://localhost:3306/devop_db}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME:root}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD:password}
```

### Build & Deployment
- Rebuilt JAR: `concert-backend-1.0.0.jar` (84.6 MB)
- Uploaded to S3: `s3://concert-dev-frontend-142fee22/backend-deploy/concert-backend-1.0.0.jar`

---

## Deployment Options

### Option A: Manual SSH Deployment (BLOCKED)
**Issue**: SSH is timing out on all EC2 instances
```bash
ssh -i concert-key.pem ubuntu@<IP>
```
**Status**: ❌ Not working (banner exchange timeout)

### Option B: AWS Systems Manager (NOT RESPONDING)
**Issue**: SSM Send-Command and Session Manager hanging
```bash
aws ssm start-session --target i-xxxxx --region us-east-1
```
**Status**: ❌ Agents not responding

### Option C: Launch New Instance with User Data (RECOMMENDED)
**Steps:**
1. Launch new t3.micro instance with proper IAM role
2. Use user-data script to download JAR and start backend
3. Configure for Docker MySQL on localhost:3306

**Required Parameters:**
- ImageId: `ami-087126591972bfe96`
- InstanceType: `t3.micro`
- KeyName: `concert-key`
- SecurityGroupIds: `sg-01d844b44878f2b16`
- SubnetId: `subnet-0cd8d035dcc0f09bb`
- IamInstanceProfile: `ConcertEC2Profile`

**User Data Script:**
```bash
#!/bin/bash
set -e

# Download JAR from S3
cd /tmp
aws s3 cp s3://concert-dev-frontend-142fee22/backend-deploy/concert-backend-1.0.0.jar . --region us-east-1

# Deploy
sudo mkdir -p /opt/concert/backend
sudo cp concert-backend-1.0.0.jar /opt/concert/backend/concert-backend.jar
sudo chown concert:concert /opt/concert/backend/concert-backend.jar
sudo chmod 755 /opt/concert/backend/concert-backend.jar

# Start Docker MySQL
docker run -d --name concert-mysql --restart unless-stopped \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=REDACTED_PASSWORD_B \
  -e MYSQL_DATABASE=concert \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=REDACTED_PASSWORD_B \
  mysql:8.4.6

# Wait for MySQL
sleep 10

# Start backend
sudo systemctl daemon-reload
sudo systemctl start concert-backend
```

### Option D: Use Terraform/CloudFormation (IF AVAILABLE)
Update the EC2 resource in Terraform with new AMI or launch configuration

### Option E: Container Registry Approach
1. Build Docker image of backend: `concert-backend:1.0.0`
2. Push to ECR
3. Run ECS task or deploy to existing instance

---

## Architecture Workaround

```
┌─────────────────────────────────────────┐
│   Frontend (S3)                         │
│   https://...s3.amazonaws.com/          │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│   API Gateway                           │
│   https://t55pviree7.execute-api...     │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│   EC2 Instance (t3.micro)               │
│   - Backend Java (port 8080)            │
│   - Docker MySQL (port 3306)            │
│   VPC: vpc-077128945cf424869            │
└─────────────────────────────────────────┘
```

**Key Point**: Backend now connects to local Docker MySQL, eliminating RPC dependency.

---

## Manual Verification Steps

Once deployment is successful:

### 1. Verify Instance Access
```bash
aws ec2 describe-instances --region us-east-1 \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,State.Name]'
```

### 2. Check Backend API
```bash
curl -I http://<instance-ip>:8080/api/auth/test
# Expected: HTTP 200, 401, or similar (not timeout/connection refused)
```

### 3. Verify Through API Gateway
```bash
curl -I https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod/api/auth/test
```

### 4. Check Backend Logs
```bash
tail -50 /opt/concert/logs/application.log
tail -50 /opt/concert/logs/service-error.log
```

### 5. Verify Docker MySQL
```bash
docker ps | grep concert-mysql
docker logs concert-mysql | tail -20
```

---

## Critical Configuration

### Database Connection
- **Host**: `localhost` (from EC2 perspective)
- **Port**: `3306`
- **Database**: `concert`
- **Username**: `admin`
- **Password**: `REDACTED_PASSWORD_B`

### Environment Variables (if manual override needed)
```bash
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/concert
export SPRING_DATASOURCE_USERNAME=admin
export SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_B
```

### Service Configuration File
Location: `/etc/systemd/system/concert-backend.service`

Ensure it points to localhost, not RDS:
```ini
[Service]
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/concert"
```

---

## Troubleshooting Checklist

- [ ] Instance is running (State = running)
- [ ] Instance status checks pass (System Status = ok, Instance Status = ok)
- [ ] Port 8080 is open in security group (sg-01d844b44878f2b16)
- [ ] Docker MySQL container is running
- [ ] Backend JAR exists at `/opt/concert/backend/concert-backend.jar`
- [ ] Backend service status shows "active (running)"
- [ ] Backend logs don't show database connection errors
- [ ] API Gateway health check returns 200

---

## Files Modified

1. **application.properties**
   - Path: `main_backend/src/main/resources/application.properties`
   - Change: Added environment variable support for database configuration
   
2. **concert-backend-1.0.0.jar**
   - Path: `main_backend/target/concert-backend-1.0.0.jar`
   - Location: `s3://concert-dev-frontend-142fee22/backend-deploy/concert-backend-1.0.0.jar`

---

## Next Steps (Priority Order)

1. **IMMEDIATE**: Launch new EC2 instance with proper user-data (Option C)
2. **Verify**: SSH into new instance and confirm backend is running
3. **Test**: Curl backend API and verify database connection
4. **Monitor**: Check CloudWatch logs for any issues
5. **Long-term**: Fix VPC isolation (move RDS to EC2 VPC or use RDS Proxy)

---

## AWS CLI Commands Reference

### Launch New Instance
```bash
aws ec2 run-instances \
  --region us-east-1 \
  --image-id ami-087126591972bfe96 \
  --instance-type t3.micro \
  --key-name concert-key \
  --security-group-ids sg-01d844b44878f2b16 \
  --subnet-id subnet-0cd8d035dcc0f09bb \
  --iam-instance-profile Name=ConcertEC2Profile \
  --user-data file://user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-backend-ec2}]'
```

### Get Instance Details
```bash
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=concert-backend-ec2" \
  --query 'Reservations[0].Instances[0].[InstanceId,PublicIpAddress,State.Name]'
```

### Check Instance Status
```bash
aws ec2 describe-instance-status --region us-east-1 \
  --instance-ids <instance-id> \
  --query 'InstanceStatuses[0].[InstanceStatus.Status,SystemStatus.Status]'
```

---

## Summary

The backend code is ready, the JAR is built and uploaded. The infrastructure connectivity issue (VPC isolation) has been worked around using Docker MySQL. The only remaining blocker is deploying the new JAR to an EC2 instance. This should be done by launching a new instance with the user-data script, which will automatically deploy and start the backend.

**Estimated time to full deployment**: 5-10 minutes after instance launch
