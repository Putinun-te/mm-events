# 🌏 SINGAPORE AWS DEPLOYMENT - COMPLETE GUIDE

**Status:** ✅ READY FOR PRODUCTION DEPLOYMENT  
**Region:** ap-southeast-1 (Singapore)  
**Date:** October 31, 2025

---

## 📋 TABLE OF CONTENTS

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Deployment Steps](#deployment-steps)
4. [Post-Deployment](#post-deployment)
5. [Troubleshooting](#troubleshooting)
6. [Cost Information](#cost-information)

---

## 🚀 QUICK START

### Option 1: Automated Deployment (Recommended)

```bash
# Navigate to AWS directory
cd /Users/putinan/development/DevOps/develop/aws

# Run deployment script (development environment)
./deploy_singapore.sh dev

# For production
./deploy_singapore.sh prod
```

The script will:
- ✅ Check all prerequisites
- ✅ Validate Terraform configuration
- ✅ Inspect existing resources
- ✅ Verify infrastructure design
- ✅ Create deployment plan
- ✅ Deploy to Singapore
- ✅ Verify all components
- ✅ Run health checks
- ✅ Generate deployment report

### Option 2: Manual Deployment

```bash
# Navigate to AWS directory
cd /Users/putinan/development/DevOps/develop/aws

# 1. Initialize Terraform
terraform init

# 2. Plan deployment
terraform plan -out=tfplan -var-file=terraform.tfvars

# 3. Review the plan (should show ~80-100 resources to create)
# Look for any errors or unexpected changes

# 4. Apply configuration
terraform apply tfplan

# 5. Verify deployment
terraform output
aws ec2 describe-vpcs --region ap-southeast-1
```

---

## 🏗️ ARCHITECTURE OVERVIEW

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────┐
│                    AWS SINGAPORE (ap-southeast-1)       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ VPC (10.0.0.0/16)                               │  │
│  │ ├── Public Subnets (2)                          │  │
│  │ │   ├── Availability Zone 1a                   │  │
│  │ │   └── Availability Zone 1b                   │  │
│  │ ├── Private Subnets (2)                         │  │
│  │ │   ├── Availability Zone 1a                   │  │
│  │ │   └── Availability Zone 1b                   │  │
│  │ ├── Internet Gateway                           │  │
│  │ ├── NAT Gateway                                │  │
│  │ └── Route Tables (Public & Private)            │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│       ┌─────────────────┼─────────────────┐            │
│       │                 │                 │            │
│  ┌────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐     │
│  │ RDS MySQL │  │ ElastiCache │  │  S3 Buckets │     │
│  │           │  │    Redis    │  │             │     │
│  │ - Backup  │  │             │  │ - Encryption│     │
│  │ - Encrypt │  │ - Auth Token│  │ - Versioning│     │
│  │ - Multi-AZ│  │ - Encrypted │  │ - Lifecycle │     │
│  └───────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │ Lambda Functions (10)                         │   │
│  │ ├── Auth Service                              │   │
│  │ ├── Event Service                             │   │
│  │ ├── Booking Service                           │   │
│  │ ├── File Upload Service                       │   │
│  │ ├── Email Service                             │   │
│  │ ├── Notification Service                      │   │
│  │ ├── Analytics Service                         │   │
│  │ ├── Cache Service                             │   │
│  │ ├── Audit Service                             │   │
│  │ └── Payment Service                           │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │ Messaging Services                            │   │
│  │ ├── SNS Topics (5)                            │   │
│  │ │   ├── Alerts                                │   │
│  │ │   ├── Email                                 │   │
│  │ │   ├── Events                                │   │
│  │ │   ├── Notifications                         │   │
│  │ │   └── SMS                                   │   │
│  │ └── SQS Queues (5)                            │   │
│  │     ├── Email Queue                           │   │
│  │     ├── Notification Queue                    │   │
│  │     ├── Booking Queue                         │   │
│  │     ├── Payment Queue                         │   │
│  │     └── Analytics Queue                       │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │ Security & Monitoring                         │   │
│  │ ├── Security Groups (Defense in Depth)       │   │
│  │ ├── CloudWatch Logs                          │   │
│  │ ├── CloudWatch Alarms (15+)                  │   │
│  │ ├── CloudWatch Dashboards                    │   │
│  │ ├── IAM Roles & Policies (21)                │   │
│  │ └── API Gateway v2                           │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Data Storage

| Service | Purpose | Capacity | Backup |
|---------|---------|----------|--------|
| RDS MySQL | Application Database | 20GB | Daily |
| DynamoDB | Session/Cache Data | 9 tables | Point-in-time |
| ElastiCache Redis | Session Store | Micro node | Snapshots |
| S3 | File Storage | Unlimited | Versioning |

### Network Topology

| Component | CIDR | AZ | Purpose |
|-----------|------|----|---------| 
| VPC | 10.0.0.0/16 | All | Main network |
| Public Subnet 1 | 10.0.1.0/24 | 1a | NAT/IGW |
| Public Subnet 2 | 10.0.2.0/24 | 1b | NAT/IGW |
| Private Subnet 1 | 10.0.11.0/24 | 1a | RDS/Lambda |
| Private Subnet 2 | 10.0.12.0/24 | 1b | RDS/Lambda |

---

## 📦 DEPLOYMENT STEPS

### Step 1: Prerequisites

```bash
# Install AWS CLI
brew install awscli

# Install Terraform
brew install terraform

# Verify installations
aws --version
terraform version

# Configure AWS credentials
aws configure
# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: ap-southeast-1
# Default output format: json

# Verify credentials
aws sts get-caller-identity
```

### Step 2: Clone and Prepare

```bash
# Navigate to project
cd /Users/putinan/development/DevOps/develop

# Verify structure
ls -la aws/

# Check configuration
cat aws/terraform.tfvars
```

Expected output:
```
aws_region            = "ap-southeast-1"
environment           = "dev"
project_name          = "concert"
vpc_cidr              = "10.0.0.0/16"
...
```

### Step 3: Run Deployment

```bash
# Make script executable (if needed)
chmod +x aws/deploy_singapore.sh

# Run deployment
aws/deploy_singapore.sh dev

# Follow prompts:
# Type 'yes' when asked to confirm deployment
```

### Step 4: Monitor Deployment

The deployment script will show:
- ✅ Prerequisite checks
- ✅ Terraform validation
- ✅ Resource inspection
- ✅ Design verification
- ✅ Plan creation
- ✅ Deployment progress
- ✅ Health checks
- ✅ Deployment report

Typical timeline: **15-20 minutes**

---

## ✅ POST-DEPLOYMENT TASKS

### 1. Retrieve Endpoints

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Get all outputs
terraform output

# Specific endpoints:
# RDS Endpoint
terraform output rds_endpoint

# ElastiCache Endpoint
terraform output elasticache_endpoint

# S3 Bucket Names
terraform output s3_bucket_names
```

### 2. Test Connectivity

```bash
# Test RDS connection
mysql -h <rds-endpoint> -u admin -p concert_db -e "SELECT 1;"

# Test Redis connection
redis-cli -h <elasticache-endpoint> ping

# Test S3 access
aws s3 ls s3://concert-event-pictures

# Test Lambda
aws lambda list-functions --region ap-southeast-1
```

### 3. Deploy Backend Application

```bash
# Build backend
cd /Users/putinan/development/DevOps/develop/main_backend
mvn clean package

# Set environment variables
export RDS_HOST=<rds-endpoint>
export RDS_USER=admin
export RDS_PASSWORD=<password>
export REDIS_HOST=<elasticache-endpoint>
export AWS_REGION=ap-southeast-1

# Run application
java -jar target/concert-backend-0.0.1-SNAPSHOT.jar
```

### 4. Deploy Frontend Application

```bash
# Build frontend
cd /Users/putinan/development/DevOps/develop/main_frontend/concert1
npm install
npm run build

# Set environment variables
export BACKEND_URL=http://<backend-url>
export AWS_REGION=ap-southeast-1

# Run frontend
npm run start
```

### 5. Verify Health

```bash
# Check all resources
aws ec2 describe-instances --region ap-southeast-1 \
  --filters "Name=tag:Environment,Values=dev"

# Check RDS status
aws rds describe-db-instances --region ap-southeast-1 \
  --db-instance-identifier concert-db-dev \
  --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Engine,EngineVersion]'

# Check Lambda functions
aws lambda list-functions --region ap-southeast-1 \
  --query 'Functions[0:5].[FunctionName,Runtime,LastModified]'

# Check S3 buckets
aws s3 ls --region ap-southeast-1
```

### 6. Configure Monitoring

```bash
# List CloudWatch alarms
aws cloudwatch describe-alarms --region ap-southeast-1

# View CloudWatch logs
aws logs describe-log-groups --region ap-southeast-1

# Create SNS subscription for alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:ap-southeast-1:ACCOUNT_ID:concert-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

---

## 🔧 TROUBLESHOOTING

### Issue: AWS Credentials Not Found

**Solution:**
```bash
# Configure AWS CLI
aws configure

# Verify
aws sts get-caller-identity

# Set environment variable
export AWS_PROFILE=default
```

### Issue: Terraform Init Fails

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform/

# Reinitialize
terraform init -upgrade

# Validate
terraform validate
```

### Issue: RDS Connection Fails

**Solution:**
```bash
# Check security group
aws ec2 describe-security-groups --region ap-southeast-1 \
  --query 'SecurityGroups[?Tags[?Value==`concert-rds-sg`]]'

# Check RDS status
aws rds describe-db-instances --region ap-southeast-1 \
  --db-instance-identifier concert-db-dev \
  --query 'DBInstances[0].DBInstanceStatus'

# Verify credentials
# Default user: admin
# Check terraform.tfvars for password
```

### Issue: S3 Bucket Not Found

**Solution:**
```bash
# List all S3 buckets
aws s3 ls

# Verify bucket region
aws s3api get-bucket-location --bucket concert-event-pictures

# Check bucket policy
aws s3api get-bucket-policy --bucket concert-event-pictures
```

### Issue: Lambda Function Not Running

**Solution:**
```bash
# Check function
aws lambda get-function --function-name concert-auth-service \
  --region ap-southeast-1

# Check logs
aws logs tail /aws/lambda/concert-auth-service \
  --region ap-southeast-1 --follow

# Check IAM role
aws iam get-role --role-name concert-lambda-role
```

### Issue: Deployment Timeout

**Solution:**
```bash
# Check Terraform state
terraform state list

# Refresh state
terraform refresh -var-file=terraform.tfvars

# Continue deployment
terraform apply tfplan_latest
```

---

## 💰 COST INFORMATION

### Estimated Monthly Costs

| Service | Tier | Cost |
|---------|------|------|
| RDS MySQL | db.t3.micro | $15-30 |
| ElastiCache | cache.t3.micro | $15-20 |
| Lambda | 1M requests | $5-15 |
| S3 | 10GB storage | $5-10 |
| Data Transfer | 1GB out | $5 |
| CloudWatch | Logs + Alarms | $5 |
| **Total (Dev)** | | **$50-75/month** |

### Production Costs

| Service | Tier | Cost |
|---------|------|------|
| RDS MySQL | db.t3.small | $30-50 |
| ElastiCache | cache.t3.small (3 nodes) | $45-60 |
| Lambda | 10M requests | $20-50 |
| S3 | 100GB storage | $10-20 |
| Data Transfer | 10GB out | $10 |
| CloudWatch | Enhanced monitoring | $15-20 |
| **Total (Prod)** | | **$150-250/month** |

### Cost Optimization Tips

1. **Use Reserved Instances**
   - Save 30-40% with 1-year commitment
   - Available for RDS and ElastiCache

2. **Enable Auto-Scaling**
   - Lambda scales automatically
   - RDS read replicas for load

3. **S3 Lifecycle Policies**
   - Archive old data
   - Delete unnecessary versions

4. **CloudWatch Log Retention**
   - Set retention policy
   - Archive to S3 if needed

5. **Consolidate Similar Resources**
   - Combine functions into one
   - Batch operations

---

## 📞 SUPPORT

### Getting Help

1. **Check Logs**
   ```bash
   # Terraform debug logs
   export TF_LOG=DEBUG
   terraform plan
   
   # AWS CloudWatch logs
   aws logs tail --follow --region ap-southeast-1 \
     /aws/lambda/concert-auth-service
   ```

2. **Verify Configuration**
   ```bash
   cat /Users/putinan/development/DevOps/develop/aws/terraform.tfvars
   ```

3. **Review AWS Console**
   - Log in to AWS Console
   - Navigate to ap-southeast-1 region
   - Check EC2, RDS, S3, Lambda dashboards

4. **Check Infrastructure Code**
   ```bash
   ls -la /Users/putinan/development/DevOps/develop/aws/
   ```

### Escalation Path

1. Check logs and error messages
2. Review Terraform state: `terraform state list`
3. Check AWS IAM permissions
4. Verify security group rules
5. Contact AWS support if needed

---

## 🎯 SUCCESS INDICATORS

After deployment, you should see:

✅ VPC created in Singapore (ap-southeast-1)
✅ RDS MySQL running and accessible
✅ ElastiCache Redis responding
✅ S3 buckets with encryption enabled
✅ Lambda functions deployed
✅ CloudWatch monitoring active
✅ Security groups configured
✅ IAM roles attached
✅ All health checks passing
✅ Deployment report generated

---

## 📚 ADDITIONAL RESOURCES

### Documentation Files

- `/Users/putinan/development/DevOps/develop/aws/DEPLOYMENT_PLAN_SINGAPORE.md`
- `/Users/putinan/development/DevOps/develop/aws/terraform.tfvars`
- `/Users/putinan/development/DevOps/develop/COMPLETE_INFRASTRUCTURE_USER_ACCOUNT.md`

### Terraform Files

All Terraform configuration files are in `/Users/putinan/development/DevOps/develop/aws/`:
- `networking.tf` - VPC, subnets, security groups
- `rds.tf` - MySQL database
- `elasticache.tf` - Redis cluster
- `s3_file_storage.tf` - S3 buckets
- `lambda/` - Lambda functions
- `messaging.tf` - SNS/SQS
- `api_gateway_lambda.tf` - API Gateway
- `iam_developer_access.tf` - IAM policies
- `variables.tf` - Variable definitions

### Contact

For support or questions, refer to deployment logs in:
- `/Users/putinan/development/DevOps/develop/aws/deployment_*.log`
- `/Users/putinan/development/DevOps/develop/aws/DEPLOYMENT_REPORT_*.md`

---

**Status:** ✅ READY FOR DEPLOYMENT

**Region:** ap-southeast-1 (Singapore)

**Next Action:** Run `./deploy_singapore.sh dev` to deploy
