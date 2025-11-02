# Temporary Direct EC2 Setup - Quick Start

## ✅ Configuration Complete

Your application is now configured to work with direct EC2 connection:

- **Backend EC2 IP**: `52.203.64.85`
- **Frontend S3 URL**: `http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com`
- **Backend JAR**: Built at `main_backend/target/concert-backend-1.0.0.jar`

## Files Updated

1. **Backend CORS** (`main_backend/src/main/java/com/concert/config/CorsConfig.java`):
   - Allows S3 website origin
   - Allows localhost for development
   - Configured for credentials and all HTTP methods

2. **Frontend Environment** (`main_frontend/concert1/.env`):
   - `BACKEND_BASE_URL=http://52.203.64.85:8080`
   - Already integrated with all API routes

## Deploy Backend to EC2

### Option 1: Manual Deployment (if you have EC2 key pair)

```bash
# 1. Copy JAR to EC2
scp -i YOUR-KEY.pem \
  main_backend/target/concert-backend-1.0.0.jar \
  ec2-user@52.203.64.85:~/

# 2. SSH to EC2
ssh -i YOUR-KEY.pem ec2-user@52.203.64.85

# 3. On EC2, set up backend
sudo mkdir -p /opt/concert
sudo mv ~/concert-backend-1.0.0.jar /opt/concert/

# 4. Create systemd service
sudo tee /etc/systemd/system/concert-backend.service > /dev/null <<'EOF'
[Unit]
Description=Concert Platform Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/concert
ExecStart=/usr/bin/java -jar /opt/concert/concert-backend-1.0.0.jar
Environment="SPRING_PROFILES_ACTIVE=prod"
Environment="SERVER_PORT=8080"
# Add these from Terraform outputs or AWS Console:
# Environment="SPRING_DATASOURCE_URL=jdbc:mysql://RDS-ENDPOINT:3306/concert"
# Environment="SPRING_DATASOURCE_USERNAME=admin"
# Environment="SPRING_DATASOURCE_PASSWORD=YOUR-DB-PASSWORD"
# Environment="SPRING_DATA_REDIS_HOST=REDIS-ENDPOINT"
# Environment="AWS_S3_EVENT_PICTURES_BUCKET=concert-event-pictures-useast1-123456789012"
# Environment="AWS_REGION=us-east-1"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 5. Start service
sudo systemctl daemon-reload
sudo systemctl enable concert-backend
sudo systemctl start concert-backend
sudo systemctl status concert-backend

# 6. Check logs
sudo journalctl -u concert-backend -f
```

### Option 2: AWS Systems Manager (No SSH key needed)

```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=concert-asg-instance" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# Start SSM session
aws ssm start-session --target $INSTANCE_ID --region us-east-1

# Note: Requires AWS Systems Manager Agent on EC2 (usually pre-installed on Amazon Linux 2023)
```

### Option 3: User Data Script (Automatic on instance launch)

Update EC2 launch template with this user data:

```bash
#!/bin/bash
# Install dependencies
dnf update -y
dnf install -y docker java-17-amazon-corretto-headless aws-cli

# Download backend JAR from S3 (upload first)
# aws s3 cp s3://YOUR-DEPLOYMENT-BUCKET/concert-backend-1.0.0.jar /opt/concert/

# Or use CodeDeploy / GitHub Actions (recommended)
```

## Deploy Frontend to S3

```bash
cd main_frontend/concert1

# 1. Build frontend
npm install
npm run generate

# 2. Sync to S3
aws s3 sync .output/public/ \
  s3://concert-dev-frontend-142fee22/concert/ \
  --region us-east-1 \
  --delete

# 3. Verify
echo "Frontend URL: http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/concert/"
```

## Get Database Credentials

```bash
cd aws/

# RDS endpoint
terraform output rds_endpoint

# RDS password (stored in Secrets Manager or manually set during creation)
aws secretsmanager get-secret-value \
  --secret-id concert-db-password \
  --region us-east-1 \
  --query SecretString \
  --output text

# Redis endpoint
aws elasticache describe-cache-clusters \
  --cache-cluster-id concert-cache \
  --region us-east-1 \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text
```

## Test the Application

### 1. Test Backend API

```bash
# Health check
curl http://52.203.64.85:8080/api/auth/test

# Should return: "Hello from secured API!"
```

### 2. Test Frontend

Open in browser:
```
http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/concert/
```

### 3. Test Full Flow

1. **Register**: Create account via frontend
2. **Login**: Sign in with credentials
3. **Create Event**: Test event creation
4. **Upload Photo**: Test S3 photo upload (if backend deployed with AWS credentials)

## Monitoring

```bash
# EC2 backend logs (if deployed as systemd service)
ssh -i YOUR-KEY.pem ec2-user@52.203.64.85
sudo journalctl -u concert-backend -f

# Or via AWS CloudWatch Logs
aws logs tail /aws/concert/application --follow --region us-east-1
```

## Troubleshooting

### Backend not accessible
```bash
# 1. Check EC2 security group allows port 8080
aws ec2 describe-security-groups \
  --group-ids sg-0084aca7c80d96e98 \
  --region us-east-1 \
  --query 'SecurityGroups[0].IpPermissions'

# 2. Check backend is running
curl http://52.203.64.85:8080/api/auth/test

# 3. SSH to EC2 and check
ssh -i YOUR-KEY.pem ec2-user@52.203.64.85
sudo systemctl status concert-backend
```

### CORS errors in browser
- Backend CORS config already allows S3 origin
- Check browser console for specific error
- Verify `BACKEND_BASE_URL` in frontend `.env`

### Database connection failed
- Ensure RDS security group allows EC2 security group
- Verify RDS endpoint and credentials in backend environment variables
- Check RDS is in same VPC as EC2

## Next Steps

1. **Submit AWS Support Request** for CloudFront + ALB approval
   - Use template in `aws/API_GATEWAY_ALB_RESTRICTION.md`
   - Expected response: 1-2 business days

2. **When Approved**: Switch to full architecture
   ```bash
   cd aws/
   mv api_gateway.tf.disabled api_gateway.tf
   terraform init
   terraform apply
   ```

3. **Update Frontend** to use API Gateway URL
   ```bash
   # In .env
   BACKEND_BASE_URL=https://api.concert-platform.com
   ```

4. **Enable CloudFront** for HTTPS frontend
   ```bash
   cd aws/
   mv cloudfront.tf.disabled cloudfront.tf
   terraform apply
   ```

## Architecture Comparison

### Current (Temporary)
```
User → S3 Website (HTTP) → EC2:8080 (Direct)
                               ↓
                          RDS + Redis
```

### Future (After AWS Approval)
```
User → CloudFront (HTTPS) → S3 Website
                               ↓
                          API Gateway
                               ↓
                          VPC Link → ALB → EC2
                                           ↓
                                      RDS + Redis
```

## Costs (Current Setup)

- EC2 t3.micro: ~$7.50/month
- RDS db.t3.micro: ~$15/month
- S3: ~$1/month
- Data transfer: ~$2/month
- **Total: ~$25.50/month**

(After API Gateway + ALB: ~$43/month)

---

**Status**: ✅ Ready to deploy
**Backend Built**: `main_backend/target/concert-backend-1.0.0.jar`
**Frontend Configured**: Using `BACKEND_BASE_URL=http://52.203.64.85:8080`
**Next Action**: Deploy backend JAR to EC2 (choose option above)
