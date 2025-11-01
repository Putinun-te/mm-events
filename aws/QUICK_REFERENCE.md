# 🚀 Quick Reference: EC2 Singapore Migration & S3 Upload Test

## ⚡ Quick Start

### One-Command Deployment:
```bash
cd /Users/putinan/development/DevOps/develop/aws
./deploy-singapore.sh
```

This script will:
1. ✅ Check prerequisites (AWS CLI, Terraform, credentials)
2. ✅ Fix deployment blockers (RDS password, ElastiCache endpoint)
3. ✅ Deploy 2 EC2 instances to Singapore (ap-southeast-1)
4. ✅ Wait for EC2 user data setup to complete
5. ✅ Test S3 upload via Lambda presigned URL
6. ✅ Optionally terminate old us-east-1 instances
7. ✅ Generate deployment summary

---

## 📋 Manual Steps (If Needed)

### 1. Fix Deployment Blockers:

#### A. Fix RDS Password Format:
```bash
cd /Users/putinan/development/DevOps/develop/aws

# Backup original
cp rds.tf rds.tf.bak

# Edit rds.tf - Find the random_password resource and update:
# FROM:
#   override_special = "/@-_"
# TO:
#   override_special = "!#$%&*()-_=+[]{}<>:?"
```

#### B. Fix ElastiCache Endpoint:
```bash
# Backup original
cp elasticache.tf elasticache.tf.bak

# Edit elasticache.tf - Find configuration_endpoint_address and replace with:
#   primary_endpoint_address
```

### 2. Deploy EC2 Infrastructure:

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Initialize Terraform
terraform init -upgrade

# Validate configuration
terraform validate

# Plan deployment (EC2 only)
terraform plan -out=tfplan-ec2 \
  -target=aws_instance.backend_primary \
  -target=aws_instance.backend_secondary \
  -target=aws_eip.backend_primary \
  -target=aws_eip.backend_secondary \
  -target=aws_security_group.backend_ec2

# Apply (deploy)
terraform apply tfplan-ec2

# Get instance IPs
terraform output backend_primary_public_ip
terraform output backend_secondary_public_ip
```

### 3. Wait for EC2 Setup (5 minutes):

The user data script automatically:
- Installs Java 21 (Corretto)
- Installs AWS CLI and utilities
- Fetches RDS and Redis credentials from Secrets Manager
- Creates Spring Boot application.properties
- Configures systemd service
- Sets up CloudWatch agent
- Creates deployment script
- **Creates S3 upload test script**

### 4. Test S3 Upload (From Your Machine):

```bash
# Request presigned URL
curl -X POST https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev/upload/event-picture \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.jpg", "contentType": "image/jpeg"}'

# Response:
# {
#   "uploadUrl": "https://concert-event-pictures-123456789012.s3...",
#   "key": "events/abc123-test.jpg",
#   "fileUrl": "https://concert-event-pictures-123456789012.s3..."
# }

# Upload file using presigned URL
curl -X PUT "<uploadUrl-from-response>" \
  -H "Content-Type: image/jpeg" \
  --upload-file test.jpg

# Verify in S3
aws s3 ls s3://concert-event-pictures-123456789012/events/ --region ap-southeast-1
```

### 5. Test S3 Upload (From EC2):

```bash
# Get EC2 IP
PRIMARY_IP=$(cd /Users/putinan/development/DevOps/develop/aws && terraform output -raw backend_primary_public_ip)

# SSH to instance
ssh -i concert-key.pem ec2-user@$PRIMARY_IP

# Run built-in test script
/opt/concert/test-s3-upload.sh

# Expected output:
# Testing S3 upload...
# API Endpoint: https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com
# Requesting presigned URL...
# Response: {"uploadUrl":"https://...","key":"events/..."}
# Upload URL: https://concert-event-pictures-123456789012.s3...
# Key: events/123abc-test.txt
# Uploading file...
# Upload complete!

# Check logs
tail -f /var/log/backend-setup.log
tail -f /opt/concert/logs/application.log
```

---

## 🔍 Verification Commands

### Check EC2 Status:
```bash
# Singapore instances
aws ec2 describe-instances \
  --region ap-southeast-1 \
  --filters "Name=tag:Name,Values=*concert-backend*" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Placement.AvailabilityZone]' \
  --output table

# Old us-east-1 instances (should terminate)
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=*concert*" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table
```

### Check S3 Buckets:
```bash
# List buckets
aws s3 ls --region ap-southeast-1 | grep concert

# List files in event-pictures bucket
aws s3 ls s3://concert-event-pictures-123456789012/ --region ap-southeast-1 --recursive

# Check bucket region
aws s3api get-bucket-location --bucket concert-event-pictures-123456789012
```

### Check Lambda Function:
```bash
# Get function info
aws lambda get-function \
  --region ap-southeast-1 \
  --function-name concert-generate-presigned-url \
  --query 'Configuration.[FunctionName,Runtime,MemorySize,Timeout]' \
  --output table

# Invoke function directly
aws lambda invoke \
  --region ap-southeast-1 \
  --function-name concert-generate-presigned-url \
  --payload '{"filename":"test.jpg","contentType":"image/jpeg"}' \
  response.json

cat response.json
```

### Check API Gateway:
```bash
# Test upload endpoint
curl -X POST https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev/upload/event-picture \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.jpg", "contentType": "image/jpeg"}'

# Test avatar endpoint
curl -X POST https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev/upload/avatar \
  -H "Content-Type: application/json" \
  -d '{"filename": "avatar.png", "contentType": "image/png"}'
```

---

## 📦 Spring Boot Deployment

### Build JAR:
```bash
cd /Users/putinan/development/DevOps/develop/main_backend

# Clean build (skip tests for speed)
mvn clean package -DskipTests

# JAR location: target/concert-backend-0.0.1-SNAPSHOT.jar
```

### Deploy to EC2:
```bash
# Get EC2 IP
PRIMARY_IP=$(cd /Users/putinan/development/DevOps/develop/aws && terraform output -raw backend_primary_public_ip)

# Upload JAR
scp -i concert-key.pem \
  /Users/putinan/development/DevOps/develop/main_backend/target/concert-backend-0.0.1-SNAPSHOT.jar \
  ec2-user@$PRIMARY_IP:/tmp/concert-backend.jar

# SSH to instance
ssh -i concert-key.pem ec2-user@$PRIMARY_IP

# Deploy using automated script
sudo /opt/concert/deploy.sh

# Check status
sudo systemctl status concert-backend
sudo systemctl start concert-backend
sudo systemctl stop concert-backend
sudo systemctl restart concert-backend

# View logs
tail -f /opt/concert/logs/application.log
tail -f /opt/concert/logs/service.log

# Test health endpoint
curl http://localhost:8080/actuator/health
```

---

## 🧹 Cleanup Old us-east-1 Instances

### List Old Instances:
```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=*concert*" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,LaunchTime]' \
  --output table
```

### Terminate:
```bash
# Replace with actual instance IDs from previous command
aws ec2 terminate-instances \
  --region us-east-1 \
  --instance-ids i-02883ae4914a92e3e i-0822088a155f99481

# Verify termination
aws ec2 describe-instances \
  --region us-east-1 \
  --instance-ids i-02883ae4914a92e3e i-0822088a155f99481 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table
```

### Cost Savings:
- 2 x t3.micro instances = ~$15/month
- **After termination: $0/month** (freed up)

---

## 🛠️ EC2 Management Commands

### SSH Access:
```bash
# Primary instance
ssh -i concert-key.pem ec2-user@<PRIMARY_IP>

# Secondary instance
ssh -i concert-key.pem ec2-user@<SECONDARY_IP>

# Copy files from EC2
scp -i concert-key.pem ec2-user@<PRIMARY_IP>:/opt/concert/logs/application.log ./
```

### Service Management:
```bash
# On EC2 instance

# Service status
sudo systemctl status concert-backend
sudo systemctl is-active concert-backend
sudo systemctl is-enabled concert-backend

# Start/Stop/Restart
sudo systemctl start concert-backend
sudo systemctl stop concert-backend
sudo systemctl restart concert-backend

# Enable/Disable auto-start
sudo systemctl enable concert-backend
sudo systemctl disable concert-backend

# View service logs
sudo journalctl -u concert-backend -f
sudo journalctl -u concert-backend --since "1 hour ago"
```

### Application Commands:
```bash
# On EC2 instance

# Check Java version
java -version

# Check application status
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/info
curl http://localhost:8080/actuator/metrics

# View logs
tail -f /opt/concert/logs/application.log
tail -f /opt/concert/logs/service.log
tail -f /var/log/backend-setup.log

# Test database connection
mysql -h <RDS_ENDPOINT> -u admin -p concert_db

# Test Redis connection
redis-cli -h <REDIS_ENDPOINT> -p 6379 --tls -a <REDIS_PASSWORD>

# Test S3 upload
/opt/concert/test-s3-upload.sh
```

### Monitoring:
```bash
# System resources
top
htop
free -h
df -h

# Network connections
netstat -tulpn | grep 8080
ss -tulpn | grep 8080

# Process info
ps aux | grep java
pgrep -f concert

# CloudWatch logs
aws logs tail /concert/backend/application --region ap-southeast-1 --follow
aws logs tail /concert/backend/service --region ap-southeast-1 --follow
```

---

## 🐛 Troubleshooting

### EC2 Won't Start:
```bash
# Check instance status
aws ec2 describe-instance-status \
  --region ap-southeast-1 \
  --instance-ids <INSTANCE_ID>

# View console output
aws ec2 get-console-output \
  --region ap-southeast-1 \
  --instance-id <INSTANCE_ID>

# Check security group
aws ec2 describe-security-groups \
  --region ap-southeast-1 \
  --group-names backend-ec2-sg
```

### S3 Upload Fails:
```bash
# Check Lambda logs
aws logs tail /aws/lambda/concert-generate-presigned-url \
  --region ap-southeast-1 \
  --follow

# Test Lambda function
aws lambda invoke \
  --region ap-southeast-1 \
  --function-name concert-generate-presigned-url \
  --payload '{"filename":"test.jpg","contentType":"image/jpeg"}' \
  response.json

# Check bucket policy
aws s3api get-bucket-policy \
  --bucket concert-event-pictures-123456789012 \
  --region ap-southeast-1
```

### Application Won't Start:
```bash
# On EC2 instance

# Check service status
sudo systemctl status concert-backend

# View full logs
sudo journalctl -u concert-backend -n 100 --no-pager

# Check application properties
cat /opt/concert/application.properties

# Check port usage
sudo netstat -tulpn | grep 8080

# Test database connection
mysql -h <RDS_ENDPOINT> -u admin -p

# Check environment variables
env | grep CONCERT
```

### RDS Connection Issues:
```bash
# Check security group
aws ec2 describe-security-groups \
  --region ap-southeast-1 \
  --filters "Name=group-name,Values=*rds*"

# Test connection from EC2
telnet <RDS_ENDPOINT> 3306
nc -zv <RDS_ENDPOINT> 3306

# Check RDS status
aws rds describe-db-instances \
  --region ap-southeast-1 \
  --db-instance-identifier concert-mysql-dev
```

---

## 📊 Monitoring Dashboard

### CloudWatch Metrics:
```bash
# EC2 CPU utilization
aws cloudwatch get-metric-statistics \
  --region ap-southeast-1 \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<INSTANCE_ID> \
  --start-time 2025-10-31T00:00:00Z \
  --end-time 2025-10-31T23:59:59Z \
  --period 3600 \
  --statistics Average

# Lambda invocations
aws cloudwatch get-metric-statistics \
  --region ap-southeast-1 \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=concert-generate-presigned-url \
  --start-time 2025-10-31T00:00:00Z \
  --end-time 2025-10-31T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

### CloudWatch Logs:
```bash
# View EC2 application logs
aws logs tail /concert/backend/application --region ap-southeast-1 --follow

# View Lambda logs
aws logs tail /aws/lambda/concert-generate-presigned-url --region ap-southeast-1 --follow

# Search for errors
aws logs filter-log-events \
  --region ap-southeast-1 \
  --log-group-name /concert/backend/application \
  --filter-pattern "ERROR"
```

---

## 📚 Important Files & Documentation

### Architecture:
- **Full architecture**: `aws/SINGAPORE_ARCHITECTURE.md`
- **Flow diagrams**: `aws/COMPLETE_FLOW_DIAGRAM.md`
- **S3 access workaround**: `aws/S3_ACCESS_WITHOUT_CLOUDFRONT.md`

### Infrastructure Code:
- **EC2 configuration**: `aws/ec2_backend.tf`
- **EC2 setup script**: `aws/user_data/backend_setup.sh`
- **S3 storage**: `aws/s3_file_storage.tf`
- **Lambda function**: `aws/lambda_presigned_url.tf`

### Deployment Scripts:
- **Main deployment**: `aws/deploy-singapore.sh`
- **This quick reference**: `aws/QUICK_REFERENCE.md`

---

## ✅ Success Checklist

After deployment, verify:

- [ ] 2 EC2 instances running in ap-southeast-1
- [ ] Primary instance has Elastic IP
- [ ] Secondary instance has Elastic IP
- [ ] Security group allows ports 8080, 443, 22
- [ ] Spring Boot application running on both instances
- [ ] S3 upload test passes from local machine
- [ ] S3 upload test passes from EC2
- [ ] Lambda presigned URL function working
- [ ] API Gateway endpoints accessible
- [ ] CloudWatch logs receiving data
- [ ] RDS connection successful (if deployed)
- [ ] Redis connection successful (if deployed)
- [ ] Old us-east-1 instances terminated
- [ ] All services in Singapore region

---

## 🎯 Next Steps

1. **Build and deploy Spring Boot application**
2. **Test all API endpoints**
3. **Set up Application Load Balancer**
4. **Configure Auto Scaling Group**
5. **Contact AWS Support for CloudFront verification**
6. **Set up CI/CD pipeline (GitHub Actions)**
7. **Add custom domain with Route 53**
8. **Enable WAF for security**
9. **Implement blue-green deployment**
10. **Create comprehensive monitoring dashboards**

---

**Region:** ap-southeast-1 (Singapore)  
**Monthly Cost:** ~$12.80 (optimizable to $0.00)  
**Status:** Ready to deploy 🚀
