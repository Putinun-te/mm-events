# AWS Tools & Services Design for Concert Application

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Free Tier Stack](#free-tier-stack)
3. [Production Stack](#production-stack)
4. [Tools & Automation](#tools--automation)
5. [Monitoring & Observability](#monitoring--observability)
6. [Security & Compliance](#security--compliance)
7. [Deployment Guide](#deployment-guide)
8. [Cost Optimization](#cost-optimization)

---

## Architecture Overview

### Current Deployment Model

The Concert application uses a **3-tier architecture** on AWS:

```
┌─────────────────────────────────────────────────────────┐
│                   USERS / CLIENTS                        │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴────────────┐
         ▼                        ▼
    ┌─────────────┐         ┌──────────────┐
    │ CloudFront  │         │  S3 Website  │
    │ (CDN)       │         │  (Static)    │
    └──────┬──────┘         └──────────────┘
           │
    ┌──────▼──────────┐
    │  Security Group │
    │   (EC2 Public)  │
    └────┬────────┬───┘
         │        │
      ┌──▼──┐  ┌──▼──┐
      │ API │  │ Web │
      │ EC2 │  │ EC2 │
      │8080 │  │3000 │
      └──┬──┘  └──┬──┘
         │        │
    ┌────▼────────▼────┐
    │  RDS MySQL       │
    │  (Private SG)    │
    └──────────────────┘

Data Flow:
Frontend → S3 (static) served via CloudFront
Browser → EC2 API (port 8080) for backend services
EC2 → RDS (port 3306) for database
```

---

## Free Tier Stack

### What's Included (12 months FREE)

| Service | Component | Cost | Quota | Notes |
|---------|-----------|------|-------|-------|
| **S3** | Static website | $0 | 5 GB | Frontend files |
| **CloudFront** | CDN | $0 | 1 TB egress/month | Global distribution |
| **EC2** | t3.micro instances (2) | $0 | 750 hrs/month shared | Backend + Web |
| **RDS** | db.t3.micro, 20 GB | $0 | 20 GB storage | MySQL database |
| **VPC** | VPC, Subnets, SG | $0 | Unlimited | Networking |
| **CloudWatch** | Logs + Metrics | $0 | 5 GB ingestion | Monitoring |
| **IAM** | Roles, Policies | $0 | Unlimited | Access control |
| **Secrets Manager** | Password storage | $0.40/month | 1-2 secrets | DB credentials |
| **Total** | | **~$0.50** | | First 12 months |

### What's Excluded (Additional Cost)

| Service | Component | Cost/Month | Why Avoided |
|---------|-----------|-----------|------------|
| **ALB** | Load Balancer | $15-20 | Not free-tier; use EC2 SG directly |
| **NAT Gateway** | Outbound internet | $32+ | Not needed for most workloads |
| **RDS Multi-AZ** | High availability | +$50 | Overkill for dev environment |
| **RDS IOPS** | Performance | $0.02/GB | Incompatible with 20GB free storage |
| **ECS Fargate** | Container service | $0.04645/vCPU/hour | Use EC2 instead |

---

## Production Stack

For scale-up from free tier to production:

```
┌─────────────────────────────────────────────────────┐
│         PRODUCTION ARCHITECTURE (Scaled)             │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Route 53 (DNS)                                     │
│      │                                              │
│  ACM (SSL Certificate)                              │
│      │                                              │
│  ┌───▼─────────────────────┐                       │
│  │  CloudFront (CDN)       │                       │
│  │  + WAF (DDoS)           │                       │
│  └───┬─────────────────────┘                       │
│      │                                              │
│      ├──────────┬──────────┐                       │
│      ▼          ▼          ▼                       │
│   ┌────────┬────────┬────────┐                     │
│   │  ALB   │ ALB TG │ ALB TG │                     │
│   │(Multi  │(Backend)|(Frontend)                  │
│   │ AZ)    │        │        │                     │
│   └────┬───┴────┬───┴────┬───┘                     │
│        │        │        │                         │
│   ┌────▼─┐  ┌───▼──┐  ┌─▼────┐                    │
│   │ASG   │  │ASG   │  │ASG   │                    │
│   │Back  │  │Front │  │Cache │                    │
│   │(Auto │  │(Auto │  │(Auto │                    │
│   │Scale)│  │Scale)│  │Scale)│                    │
│   └────┬─┘  └───┬──┘  └─┬────┘                    │
│        │        │       │                         │
│        └────┬───┴───┬───┘                         │
│             ▼       ▼                             │
│         ┌─────────────────┐                       │
│         │ RDS Aurora      │                       │
│         │ (Multi-AZ, HA)  │                       │
│         │ + Read Replicas │                       │
│         └──────┬──────────┘                       │
│                │                                  │
│         ┌──────▼──────────┐                       │
│         │ S3 (backups)    │                       │
│         └─────────────────┘                       │
│                                                   │
└─────────────────────────────────────────────────────┘
```

**Production services added:**
- **Route 53** – DNS with failover
- **ACM** – SSL/TLS certificates
- **WAF** – Web Application Firewall + DDoS protection
- **ALB** – Application Load Balancer with SSL termination
- **Auto Scaling Groups** – Dynamic scaling based on load
- **RDS Aurora** – MySQL with multi-AZ, automatic failover
- **CloudWatch** – Enhanced monitoring, alarms, dashboards
- **SNS/SQS** – Event messaging
- **Lambda** – Serverless functions
- **DynamoDB** – NoSQL cache (optional)
- **S3** – Backups, artifacts, static content

---

## Tools & Automation

### 1. Infrastructure as Code (Terraform)

**Purpose:** Define all AWS resources in code

**Files:**
- `main.tf` – Core VPC, networking, security groups
- `s3_cloudfront.tf` – Static website hosting
- `rds.tf` – Database configuration
- `ec2.tf` – Virtual machines (backend/frontend)
- `iam.tf` – Roles and policies
- `cloudwatch.tf` – Logs and monitoring
- `variables.tf` – Input variables
- `outputs.tf` – Output values

**Usage:**
```bash
# Free tier
make free-tier-plan
make free-tier-apply

# Production
make plan
make apply

# Destroy
make destroy
```

### 2. Makefile Targets

**Build & Deploy:**
```bash
make init               # Initialize Terraform
make plan              # Plan changes
make apply             # Apply Terraform
make destroy           # Destroy resources
make validate          # Validate configuration
make fmt               # Format HCL files
```

**Docker & ECR:**
```bash
make aws-login         # Login to ECR
make aws-build-all     # Build and push all images
make s3-sync           # Sync frontend to S3
make cf-invalidate     # Invalidate CloudFront cache
```

**Free Tier Specific:**
```bash
make free-tier-plan    # Plan free-tier deployment
make free-tier-apply   # Apply free-tier
make free-tier-destroy # Destroy free-tier
make free-tier-status  # Check status
```

**Monitoring:**
```bash
make logs              # Follow CloudWatch logs
make status            # Check deployment status
make outputs           # Show Terraform outputs
make monitor-services  # Check ECS services
make monitor-rds       # Check RDS status
```

### 3. Deployment Pipeline (GitHub Actions - Optional)

**`.github/workflows/deploy.yml`** (example structure):

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main, develop]

env:
  AWS_REGION: us-east-1

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Plan
        run: |
          cd aws
          terraform init
          terraform plan -out=tfplan

  apply:
    needs: plan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Apply
        run: |
          cd aws
          terraform apply tfplan
```

---

## Monitoring & Observability

### 1. CloudWatch

**Logs:**
- EC2 Docker output → `/concert/ec2/docker`
- System logs → `/concert/ec2/system`
- RDS error logs → `/aws/rds/instance/concert-mysql/error`

**Metrics:**
- EC2 CPU, Memory, Disk
- RDS CPU, Database Connections
- CloudFront requests, errors
- S3 PUT/GET operations

**Log Insights Queries:**

```sql
-- Find errors
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /Exception/
| stats count() by bin(5m)

-- API performance
fields @duration
| filter @message like /api/
| stats pct(@duration, 95) as p95, pct(@duration, 99) as p99

-- Database connections
fields @message
| filter @message like /connection/
| stats count() by @message
```

### 2. CloudWatch Alarms

**Set up alerts for:**

```bash
# High CPU
aws cloudwatch put-metric-alarm \
  --alarm-name backend-high-cpu \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --threshold 80 \
  --period 300 \
  --comparison-operator GreaterThanThreshold

# RDS database full
aws cloudwatch put-metric-alarm \
  --alarm-name rds-storage-full \
  --metric-name FreeStorageSpace \
  --namespace AWS/RDS \
  --statistic Average \
  --threshold 2000000000 \  # 2 GB
  --comparison-operator LessThanThreshold

# CloudFront errors
aws cloudwatch put-metric-alarm \
  --alarm-name cf-errors \
  --metric-name 4XXError \
  --namespace AWS/CloudFront \
  --statistic Sum \
  --threshold 100 \
  --period 300
```

### 3. CloudWatch Dashboards

```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name Concert-Monitoring \
  --dashboard-body file://dashboard.json
```

**Dashboard metrics:**
- EC2 instances (running, stopped)
- RDS database (connections, queries)
- CloudFront (requests, errors, latency)
- S3 (PUT/GET operations)
- Cost forecast

---

## Security & Compliance

### 1. IAM Security

**Least Privilege Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. Secrets Management

**Store sensitive data in AWS Secrets Manager:**

```bash
# RDS password
aws secretsmanager create-secret \
  --name concert/rds/password \
  --secret-string $(openssl rand -base64 32)

# Retrieve in application
aws secretsmanager get-secret-value --secret-id concert/rds/password
```

### 3. VPC Security

- **Private subnets** for database (no internet access)
- **Public subnets** for EC2 (if needed for SSH)
- **Security Groups** – Whitelist only needed ports
- **Network ACLs** – Optional additional layer

**Example Security Group rules:**

```hcl
# RDS Security Group
ingress {
  from_port       = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_groups = [aws_security_group.ec2.id]  # Only from EC2
}

# EC2 Security Group
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Only your IP
}

ingress {
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # API open to public
}
```

---

## Deployment Guide

### Step 1: Prerequisites

```bash
# Install AWS CLI
brew install awscli

# Install Terraform
brew install terraform

# Install Docker
brew install docker

# Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

### Step 2: Clone & Setup

```bash
cd /Users/putinan/development/DevOps/develop
git checkout feature/aws-deployment
cd aws
```

### Step 3: Free Tier Deployment

```bash
# Initialize Terraform
terraform init

# Plan free-tier deployment
make free-tier-plan

# Review the plan (should include S3, CloudFront, RDS, EC2)

# Apply
make free-tier-apply

# Wait 5-10 minutes for resources to create
```

### Step 4: Build & Upload Frontend

```bash
# Build frontend
cd ../main_frontend/concert1
npm run build

# Sync to S3
cd ../../aws
make s3-sync

# Invalidate CloudFront cache
make cf-invalidate
```

### Step 5: Access Application

```bash
# Get CloudFront domain
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
echo "Frontend: https://$CLOUDFRONT_DOMAIN"

# Get backend IP
BACKEND_IP=$(terraform output -raw backend_ec2_eip)
echo "Backend API: http://$BACKEND_IP:8080/api"

# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
echo "Database: $RDS_ENDPOINT"

# Open in browser
open "https://$CLOUDFRONT_DOMAIN"
```

---

## Cost Optimization

### 1. Free Tier Strategy (First 12 Months)

| Optimization | Savings |
|--------------|---------|
| Use t3.micro EC2 | $0 (free tier) |
| Skip ALB | Save $15-20/month |
| No Multi-AZ RDS | Save $50/month |
| No RDS IOPS | Save $0.02/GB/month |
| Single NAT Gateway | Save $32/month |
| S3 lifecycle policies | Save storage |
| **Total 12-month savings** | **~$600+** |

### 2. Beyond 12 Months

**Cost per month (minimal):**

```
EC2 (2x t3.micro): $15
RDS (db.t3.micro): $20
S3 storage:        $1
CloudFront:        $5
Data transfer:     $5
CloudWatch:        $1
────────────────
TOTAL:             ~$47/month
```

**Ways to reduce:**
- Stop EC2 when not in use → Save 50%
- Switch to Lightsail → Fixed $5-10/month
- Use Reserved Instances → Save 30-50%
- Enable S3 Intelligent-Tiering → Auto-optimize storage

### 3. Cost Monitoring

**Set up budgets:**

```bash
# Create $10/month budget alert
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget BudgetName=Concert-Monthly,BudgetLimit=10,BudgetType=MONTHLY,TimeUnit=MONTHLY \
  --notifications-with-subscribers file://notification.json
```

**Monitor with Cost Explorer:**
- **AWS Console** > **Billing & Cost Management** > **Cost Explorer**
- Filter by: Service, Linked Account, Region
- Set alert at $5, $10, $20 depending on free tier remaining

---

## 🎯 Quick Start Commands

```bash
# One-liner deployment (free tier)
cd /Users/putinan/development/DevOps/develop/aws && \
  terraform init && \
  make free-tier-plan && \
  make free-tier-apply && \
  echo "Deployment complete!"

# Upload frontend after build
cd ../main_frontend/concert1 && \
  npm run build && \
  cd ../../aws && \
  make s3-sync && \
  make cf-invalidate

# Monitor everything
make free-tier-status
make logs
make monitor-services
```

---

## 📞 Troubleshooting

### Problem: "ALB account limitation"
**Solution:** Not an issue for free tier (we skip ALB anyway)

### Problem: "RDS IOPS storage < 400GB"
**Solution:** Already fixed (we use 20 GB, no IOPS)

### Problem: "Exceeding free tier quota"
**Solution:**
- Check CloudWatch Metrics
- Review AWS Billing Dashboard
- Stop unused EC2 instances
- Reduce CloudWatch log retention

### Problem: High data transfer costs
**Solution:**
- Use CloudFront (included in free tier)
- Keep data transfer within AWS region
- Use S3 Gateway Endpoint to avoid NAT charges

---

## 📚 Reference Documents

- [FREE_TIER_STRATEGY.md](./FREE_TIER_STRATEGY.md) – Detailed free tier guide
- [README_S3_CLOUDFRONT.md](./README_S3_CLOUDFRONT.md) – S3/CloudFront setup
- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS Pricing Calculator](https://calculator.aws/)
- [Cost Optimization Best Practices](https://aws.amazon.com/cost-optimization/)

---

**Status:** ✅ Ready for Deployment  
**Last Updated:** October 30, 2025  
**Architecture Version:** 1.0 (Free Tier Optimized)

