# AWS Workflow Guide - Concert Application

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [Infrastructure Overview](#infrastructure-overview)
3. [Deployment Procedures](#deployment-procedures)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [Operational Procedures](#operational-procedures)
6. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
7. [Cost Management](#cost-management)

---

## 🚀 Quick Start

### Current Deployment Status
✅ **Infrastructure**: All resources deployed and running
✅ **Frontend**: S3 bucket ready for static assets
✅ **Backend**: EC2 instances running and accepting connections
✅ **Database**: RDS MySQL ready for application use

### Access Your Application

**Frontend (S3 Website):**
```
http://concert-dev-frontend-d453b7db.s3-website-us-east-1.amazonaws.com
```

**Backend API:**
- Instance 1: `ssh -i concert-key.pem ubuntu@44.200.159.251`
- Instance 2 (Frontend): `ssh -i concert-key.pem ubuntu@3.94.54.28`

**Database (RDS):**
- Endpoint: `concert-mysql.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306`
- Port: 3306
- Username: `concert_user`
- Database: `concert_db`

---

## 🏗️ Infrastructure Overview

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Account (us-east-1)                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              VPC: 10.0.0.0/16                        │  │
│  │                                                      │  │
│  │  Public Subnets:                Private Subnets:    │  │
│  │  ┌──────────┐    ┌──────────┐  ┌──────────┐        │  │
│  │  │ Frontend │    │ NAT GW 1 │  │   RDS    │        │  │
│  │  │ EC2 (t3) │    │          │  │ (MySQL)  │        │  │
│  │  └──────────┘    └──────────┘  └──────────┘        │  │
│  │                                                      │  │
│  │  ┌──────────┐    ┌──────────┐                       │  │
│  │  │ Backend  │    │ NAT GW 2 │                       │  │
│  │  │ EC2 (t3) │    │          │                       │  │
│  │  └──────────┘    └──────────┘                       │  │
│  │                                                      │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │  Internet Gateway                           │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           S3 Static Website                          │  │
│  │  (concert-dev-frontend-d453b7db)                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Monitoring & Logging                       │  │
│  │  - CloudWatch Logs (/ecs/concert)                    │  │
│  │  - CloudWatch Metrics                                │  │
│  │  - AWS Systems Manager Session Manager               │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Resources Deployed

| Resource | Name | Type | Status |
|----------|------|------|--------|
| **Compute** | EC2 Backend | t3.micro | ✅ Running (44.200.159.251) |
| | EC2 Frontend | t3.micro | ✅ Running (3.94.54.28) |
| **Database** | RDS MySQL | db.t3.micro | ✅ Running |
| **Storage** | S3 Bucket | Static Website | ✅ Ready |
| **Networking** | VPC | 10.0.0.0/16 | ✅ Ready |
| | NAT Gateways | (2x) | ✅ Ready |
| **Security** | Security Groups | (3x) | ✅ Configured |
| **Monitoring** | CloudWatch Logs | (2x) | ✅ Active |
| **Secrets** | Secrets Manager | RDS Password | ✅ Stored |

---

## 📦 Deployment Procedures

### 1. Infrastructure Deployment

#### Pre-requisites
```bash
# Verify AWS CLI configuration
aws sts get-caller-identity

# Verify Terraform installation
terraform version

# Verify Docker is running (for container images)
docker ps
```

#### Deploy Infrastructure
```bash
cd /Users/putinan/development/DevOps/develop/aws

# Plan deployment
terraform plan -out=tfplan

# Review plan (should show 53+ resources)
# Apply deployment
terraform apply tfplan

# Deployment typically takes 10-15 minutes
```

#### Verify Deployment
```bash
# Get all outputs
terraform output

# Verify EC2 instances
aws ec2 describe-instances --region us-east-1 \
  --query 'Reservations[].Instances[].{ID:InstanceId,IP:PublicIpAddress,State:State.Name}' \
  --filters Name=tag:Project,Values=Concert

# Verify RDS
aws rds describe-db-instances --region us-east-1 \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}'

# Verify S3
aws s3 ls | grep concert
```

### 2. Frontend Deployment

#### Build Frontend
```bash
cd /Users/putinan/development/DevOps/develop/main_frontend/concert1

# Install dependencies
npm install

# Build for production
npm run build

# Output: .output/public/
```

#### Deploy to S3
```bash
cd /Users/putinan/development/DevOps/develop/aws

# Get S3 bucket name
BUCKET=$(terraform output -raw frontend_s3_bucket_name)

# Sync build to S3
aws s3 sync ../main_frontend/concert1/.output/public/ \
  s3://$BUCKET/ \
  --delete \
  --region us-east-1

# Verify upload
aws s3 ls s3://$BUCKET/ --recursive
```

#### Test Frontend
```bash
# Get S3 website URL
terraform output -raw s3_website_endpoint

# Visit in browser: http://concert-dev-frontend-d453b7db.s3-website-us-east-1.amazonaws.com
```

### 3. Backend Deployment

#### Build Backend Docker Image
```bash
cd /Users/putinan/development/DevOps/develop/main_backend

# Build Docker image
docker build -t concert-backend:latest .

# Tag for ECR
docker tag concert-backend:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest
```

#### Push to ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Push image
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest
```

#### Deploy to EC2
```bash
# Get backend EC2 IP
BACKEND_IP=$(terraform output -raw backend_ec2_public_ip)

# SSH into instance
ssh -i concert-key.pem ubuntu@$BACKEND_IP

# On the instance:
# Pull and run the Docker image
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest
docker run -d \
  --name concert-backend \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-mysql.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert_db \
  -e SPRING_DATASOURCE_USERNAME=concert_user \
  -e SPRING_DATASOURCE_PASSWORD=$(aws secretsmanager get-secret-value --secret-id concert/rds/password-2025-10-30-1830 --query SecretString --output text) \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest

# Verify service
curl http://localhost:8080/api/health
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: 123456789012
  ECR_BACKEND_REPO: concert/concert-backend
  ECR_FRONTEND_REPO: concert/concert-frontend

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to ECR
        run: |
          aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

      - name: Build and push Backend image
        run: |
          cd main_backend
          docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:$GITHUB_SHA .
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:$GITHUB_SHA
          docker tag $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:$GITHUB_SHA \
                     $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_BACKEND_REPO:latest

      - name: Build Frontend
        run: |
          cd main_frontend/concert1
          npm install
          npm run build

      - name: Deploy Frontend to S3
        run: |
          BUCKET=$(aws s3 ls | grep concert | awk '{print $3}')
          aws s3 sync main_frontend/concert1/.output/public/ s3://$BUCKET/ --delete

      - name: Notify Deployment
        if: always()
        run: |
          echo "Deployment completed"
          echo "Frontend: http://concert-dev-frontend-d453b7db.s3-website-us-east-1.amazonaws.com"
          echo "Backend: http://44.200.159.251:8080"
```

### Manual Deployment Checklist

- [ ] Code reviewed and merged to main branch
- [ ] Docker images built and tested locally
- [ ] Docker images pushed to ECR
- [ ] Backend deployed to EC2 instance
- [ ] Frontend built and deployed to S3
- [ ] All smoke tests passing
- [ ] Deployment logged in CloudWatch

---

## 📊 Operational Procedures

### Health Checks

```bash
# Backend health
curl -s http://44.200.159.251:8080/api/health | jq .

# Database connectivity
mysql -h concert-mysql.csfsyoiy61fp.us-east-1.rds.amazonaws.com \
      -u concert_user -p \
      -e "SELECT 1;"

# S3 website
curl -I http://concert-dev-frontend-d453b7db.s3-website-us-east-1.amazonaws.com

# EC2 instances status
aws ec2 describe-instance-status --instance-ids i-02883ae4914a92e3e i-0822088a155f99481
```

### Database Backup & Restore

```bash
# Automated backups are enabled (7-day retention)
aws rds describe-db-instances --db-instance-identifier concert-mysql \
  --query 'DBInstances[0].{BackupRetention:BackupRetentionPeriod,LatestRestorableTime:LatestRestorableTime}'

# Manual backup
aws rds create-db-snapshot \
  --db-instance-identifier concert-mysql \
  --db-snapshot-identifier concert-backup-$(date +%Y%m%d-%H%M%S)

# List backups
aws rds describe-db-snapshots --db-instance-identifier concert-mysql
```

### Log Monitoring

```bash
# View CloudWatch logs
aws logs tail /ecs/concert --follow

# View EC2 system logs
aws logs tail /concert/ec2/system --follow

# View Docker logs
aws logs tail /concert/ec2/docker --follow
```

### Scaling Operations

#### Horizontal Scaling (Add more EC2 instances)

Currently deployed: 2 EC2 instances (t3.micro)

To add more instances:
```bash
cd /Users/putinan/development/DevOps/develop/aws

# Update desired count in Makefile or directly
# Currently: frontend[0] and backend[0]
# To add more: modify count in ec2.tf and re-apply
```

#### Vertical Scaling (Upgrade instance type)

```bash
# Current: t3.micro (free tier)
# To upgrade: Change ec2_instance_type in terraform.tfvars
# Example: t3.small, t3.medium, etc.

cd /Users/putinan/development/DevOps/develop/aws
# Edit terraform.tfvars: ec2_instance_type = "t3.small"
terraform plan
terraform apply
```

#### Database Scaling

```bash
# Current: db.t3.micro (20 GB storage, free tier)
# To upgrade storage:
# Edit terraform.tfvars: db_allocated_storage = 100

# To upgrade instance type (not in free tier):
# Edit terraform.tfvars: db_instance_class = "db.t3.small"

terraform plan
terraform apply
```

### Disaster Recovery

#### Backup & Restore Procedure

```bash
# 1. Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier concert-mysql \
  --db-snapshot-identifier concert-restore-point-$(date +%Y%m%d)

# 2. Wait for snapshot completion
aws rds describe-db-snapshots \
  --db-snapshot-identifier concert-restore-point-* \
  --query 'DBSnapshots[].{ID:DBSnapshotIdentifier,Status:Status}'

# 3. Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier concert-mysql-restored \
  --db-snapshot-identifier concert-restore-point-20251030

# 4. Wait for restore and verify
aws rds describe-db-instances --db-instance-identifier concert-mysql-restored
```

#### Rebuild Infrastructure

```bash
# Destroy everything
cd /Users/putinan/development/DevOps/develop/aws
terraform destroy -auto-approve

# Re-deploy (data will be restored from snapshots)
terraform apply -auto-approve
```

---

## 🔍 Monitoring & Troubleshooting

### CloudWatch Metrics

```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-02883ae4914a92e3e \
  --start-time 2025-10-30T00:00:00Z \
  --end-time 2025-10-30T23:59:59Z \
  --period 300 \
  --statistics Average

# RDS CPU
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=concert-mysql \
  --start-time 2025-10-30T00:00:00Z \
  --end-time 2025-10-30T23:59:59Z \
  --period 300 \
  --statistics Average
```

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| EC2 instance not accessible | Security group blocking SSH | Check port 22 in security group |
| Database connection fails | RDS in private subnet | Ensure EC2 can reach RDS through security groups |
| S3 website returns 403 | Bucket policy not applied | Re-apply bucket policy and public access settings |
| Frontend not loading | S3 bucket or CloudFront issue | Check S3 bucket website hosting config |
| Backend API timeout | EC2 instance down | SSH into instance and restart Docker container |

### Access EC2 Instances

```bash
# SSH into backend
ssh -i concert-key.pem ubuntu@44.200.159.251

# SSH into frontend
ssh -i concert-key.pem ubuntu@3.94.54.28

# Once connected, check services
docker ps
docker logs concert-backend
curl http://localhost:8080/api/health
```

### Session Manager (No SSH needed)

```bash
# Start session
aws ssm start-session --target i-02883ae4914a92e3e --region us-east-1

# Once in session:
curl http://localhost:8080/api/health
docker ps
```

---

## 💰 Cost Management

### Current Monthly Cost

| Service | Free Tier | Current Usage | Monthly Cost |
|---------|-----------|---------------|--------------|
| **EC2** | 750 hrs | 2 x t3.micro | $0.00 |
| **RDS** | 750 hrs + 20 GB | 1 x db.t3.micro + 20 GB | $0.00 |
| **S3** | 5 GB | ~2 GB | $0.00 |
| **Data Transfer** | 100 GB | ~1-5 GB | $0.00 |
| **Secrets Manager** | None | RDS password | $0.40 |
| **CloudWatch Logs** | 5 GB ingestion | ~0.5 GB | $0.00 |
| | | **TOTAL** | **$0.40/mo** |

### Cost Optimization Tips

1. **Stop unused resources**
   ```bash
   # Stop EC2 instances when not needed
   aws ec2 stop-instances --instance-ids i-02883ae4914a92e3e
   
   # Start when needed again
   aws ec2 start-instances --instance-ids i-02883ae4914a92e3e
   ```

2. **Monitor data transfer**
   ```bash
   aws ec2 describe-network-interfaces \
     --query 'NetworkInterfaces[].[BytesIn,BytesOut]'
   ```

3. **Set up billing alerts**
   ```bash
   # Create a budget alert at $1/month to catch any unexpected charges
   aws budgets create-budget \
     --account-id 123456789012 \
     --budget file://budget.json
   ```

4. **After free tier expires (12 months)**
   - Estimated production cost: ~$47/month
   - Consider: Reserved Instances (save 30-50%), Lightsail ($5-10/mo fixed)

---

## 📝 Maintenance Schedule

### Weekly
- [ ] Check CloudWatch metrics for anomalies
- [ ] Review CloudWatch logs for errors
- [ ] Verify all services are healthy
- [ ] Check free tier usage

### Monthly
- [ ] Review AWS bill
- [ ] Create manual database backup
- [ ] Update Docker images to latest patches
- [ ] Run security scan with AWS Security Hub

### Quarterly
- [ ] Review infrastructure for optimization opportunities
- [ ] Update Terraform configurations
- [ ] Test disaster recovery procedure
- [ ] Review and update CI/CD pipeline

---

## 📚 Additional Resources

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Spring Boot Docker Guide](https://spring.io/guides/gs/spring-boot-docker/)
- [Nuxt Deployment Guide](https://nuxt.com/docs/guide/deploy/overview)

---

## 🆘 Support & Contacts

- **AWS Console**: https://console.aws.amazon.com
- **AWS Support**: Via AWS Management Console
- **Repository**: Your GitHub repository
- **Documentation**: `/Users/putinan/development/DevOps/develop/docs/`

---

**Last Updated:** October 30, 2025
**Deployment Status:** ✅ Live and Running
**Free Tier Remaining:** 12 months

