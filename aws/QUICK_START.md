# AWS Deployment Quick Start Guide

Welcome to the Concert Application AWS deployment setup! This guide will help you get your application running on AWS in minutes.

## 🚀 Quick Overview

```
┌─────────────────────────────────────────────┐
│   Concert Application on AWS                │
├─────────────────────────────────────────────┤
│ • ECS Fargate (containers)                  │
│ • Application Load Balancer                 │
│ • RDS MySQL Database                        │
│ • Auto-Scaling Services                     │
│ • CloudWatch Monitoring                     │
│ • Infrastructure as Code (Terraform)        │
└─────────────────────────────────────────────┘
```

## 📋 Prerequisites

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0
- [ ] Docker installed
- [ ] Git configured

## 🎯 Step-by-Step Setup (15 minutes)

### Step 1: Prepare AWS Account

```bash
# Set your AWS region
export AWS_REGION=us-east-1

# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
```

### Step 2: Create ECR Repositories

```bash
# Create repositories
aws ecr create-repository \
  --repository-name concert/concert-backend \
  --region $AWS_REGION

aws ecr create-repository \
  --repository-name concert/concert-frontend \
  --region $AWS_REGION
```

### Step 3: Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push images
cd aws
make aws-build-all
cd ..
```

### Step 4: Configure Terraform

```bash
cd aws

# Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit the file with your values
nano terraform.tfvars
```

**Important values to update:**

```hcl
# Credentials (CHANGE THESE!)
db_password = "YourSuperSecurePassword123!"

# Image URIs (from ECR)
backend_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest"
frontend_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-frontend:latest"
```

### Step 5: Initialize Terraform

```bash
terraform init
```

### Step 6: Review and Deploy

```bash
# See what will be created
terraform plan

# Create all resources
terraform apply

# Get your application URL
terraform output application_url
```

## ✅ Verify Deployment

```bash
# Check services are running
make monitor-services

# Check RDS status
make monitor-rds

# View application logs
make logs
```

## 🌐 Access Your Application

After deployment completes, you'll get:

- **Frontend URL**: `http://your-alb-dns-name.elb.amazonaws.com`
- **API URL**: `http://your-alb-dns-name.elb.amazonaws.com/api`

## 📊 Monitoring

### View Logs
```bash
make logs
```

### Check Service Status
```bash
make monitor-services
```

### View All Resources
```bash
terraform output
```

## 🛠️ Common Tasks

### Update Application Code

1. Make code changes
2. Push to GitHub
3. GitHub Actions automatically:
   - Builds Docker images
   - Pushes to ECR
   - Updates ECS services

### Scale Services

```bash
# Scale backend to 3 tasks
aws ecs update-service \
  --cluster concert-cluster \
  --service concert-backend-service \
  --desired-count 3 \
  --region $AWS_REGION
```

### View Database

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint | cut -d: -f1)

# Connect with MySQL client
mysql -h $RDS_ENDPOINT -u concert_user -p concert_db
```

## 🧹 Clean Up

**WARNING: This deletes everything!**

```bash
cd aws
make destroy
```

## 💰 Cost Estimation

| Service | Approximate Cost |
|---------|-----------------|
| ECS Fargate | $40-50/month |
| RDS MySQL | $10/month |
| ALB | $20/month |
| NAT Gateway | $35/month |
| Data Transfer | $5-15/month |
| **TOTAL** | **~$110-130/month** |

## 🐛 Troubleshooting

### "Services not becoming healthy"

Check target health:
```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --region $AWS_REGION
```

Check container logs:
```bash
make logs
```

### "RDS connection failed"

1. Verify RDS is running: `make monitor-rds`
2. Check security groups allow ECS → RDS
3. Verify database password is correct

### "Cannot push to ECR"

Verify login worked:
```bash
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/concert/concert-backend:latest
```

## 📚 Full Documentation

For detailed information, see `aws/README.md`

## 🆘 Need Help?

1. Check AWS CloudWatch Logs: `make logs`
2. Check ECS Task Status: `make monitor-tasks`
3. Check ALB Health: `make monitor-alb-health`
4. Review Terraform output: `terraform output`

## ⭐ Next Steps

After successful deployment:

1. ✅ Configure domain name (Route 53)
2. ✅ Setup HTTPS/SSL (ACM Certificate)
3. ✅ Enable auto-backups for RDS
4. ✅ Setup CloudWatch alarms
5. ✅ Configure VPC Flow Logs
6. ✅ Enable AWS WAF on ALB

## 📖 Learn More

- [Terraform AWS Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [RDS MySQL Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MySQL.Concepts.html)

---

**Happy Deploying! 🚀**

For questions or issues, check the troubleshooting section in `aws/README.md`
