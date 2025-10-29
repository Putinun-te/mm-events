# AWS Free Tier Deployment Strategy for Concert

## 📊 Overview

This document details how to deploy the Concert application on AWS **free tier**, what's included, what has usage limits, and what will cost money. Following this guide, you can run the full stack for **12 months free**, with minimal ongoing costs after that.

---

## 🎯 Free Tier Architecture

### Services Used (Free-Tier Eligible)

| Service | Free Tier Allowance | How Long | Notes |
|---------|------------------|----------|-------|
| **S3** | 5 GB storage | 12 months | Ideal for static frontend hosting |
| **CloudFront** | 1 TB egress/month | 12 months | Global CDN for frontend delivery |
| **RDS (MySQL)** | db.t3.micro, 20 GB storage | 12 months | Single-AZ, no Multi-AZ, no IOPS |
| **EC2** | t3.micro or t2.micro, 750 hrs/month | 12 months | 2 instances = 750 hrs total (shared pool) |
| **Elastic IPs** | 1 static IP | Always free | Each additional EIP costs $0.005/hour if not attached |
| **VPC/Security Groups** | 5 Security Groups | Always free | No additional charge |
| **CloudWatch Logs** | 5 GB ingestion, 5 GB storage | 12 months | 7-day retention default |
| **NAT Gateway** | FIRST 45 GB/month | 12 months | Each subsequent GB: $0.045 |
| **Data Transfer** | 100 GB egress/month | 12 months | After 100 GB: $0.09/GB (very cheap unless high traffic) |

### Services **NOT** Included (Incur Charges)

| Service | Monthly Cost (Approx) | Why We Avoid It |
|---------|---------------------|-----------------|
| **ALB (Application Load Balancer)** | $15-20 | Not free-tier eligible; use EC2 + security groups instead |
| **RDS Multi-AZ** | $50+ | Doubles your database cost; not needed for dev |
| **RDS IOPS** | $0.02/GB/month | Removed; using gp3 without IOPS |
| **Lambda** | $0.20-0.50 | (Not used in our stack) |
| **ECS on EC2 (hourly)** | Minimal if on EC2 instances | ECS cluster itself is free; you pay for compute |
| **DynamoDB** | $0.00 (free tier exists but not needed) | Using RDS instead |

---

## 🏗️ Free Tier Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Free Tier Stack                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Users/Browser                                                    │
│         │                                                         │
│         ├─────► CloudFront CDN (1 TB free egress)                │
│         │              │                                         │
│         │              ├─► S3 Static Website (5 GB free)         │
│         │              │   (Frontend HTML/CSS/JS)                │
│         │              │                                         │
│         │              └─► Cache invalidation                    │
│         │                                                         │
│         └─────► EC2 Security Group                               │
│                       │                                          │
│              ┌────────┴──────────┐                               │
│              │                   │                               │
│         Backend EC2         Frontend EC2                         │
│      (t3.micro/t2.micro)   (t3.micro/t2.micro)                  │
│      Spring Boot API       Nuxt Server                           │
│      Port 8080             Port 3000                             │
│              │                   │                               │
│              └────────┬──────────┘                               │
│                       │                                          │
│              RDS MySQL Database                                  │
│          (db.t3.micro, 20 GB)                                    │
│           Single-AZ, No Multi-AZ                                 │
│                       │                                          │
│         CloudWatch Logs (7-day retention)                        │
│         /concert/ec2/docker, /concert/ec2/system                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

Cost Summary (12-month free tier):
✅ S3 Storage: FREE
✅ CloudFront: FREE (1 TB/month egress)
✅ RDS: FREE (20 GB, single-AZ)
✅ EC2 (2x t3.micro): FREE (shared 750 hrs/month)
✅ Elastic IPs (1): FREE
✅ VPC/SGs: FREE
✅ CloudWatch: FREE (5 GB logs)
─────────────────────────────
Total: $0 for 12 months
```

---

## 📋 What We're Deploying (Free Tier Version)

### 1. **Frontend: S3 + CloudFront**
- ✅ Upload built frontend to S3 bucket
- ✅ Serve via CloudFront global CDN
- ✅ Automatic cache invalidation on updates
- ✅ **Cost:** Completely free for first 12 months

### 2. **Backend: EC2 + RDS**
- ✅ Backend Spring Boot on t3.micro EC2
- ✅ MySQL database (db.t3.micro, 20 GB)
- ✅ Docker container on EC2 using user data script
- ✅ Single EC2 instance (or 2 for HA, but both count toward 750 hrs)
- ✅ **Cost:** Completely free for first 12 months

### 3. **Networking & Security**
- ✅ VPC with public/private subnets
- ✅ Security groups for EC2 and database
- ✅ 1 Elastic IP (static IP for the backend EC2)
- ✅ **Cost:** Completely free

### 4. **Monitoring & Logs**
- ✅ CloudWatch Logs for EC2 Docker output
- ✅ CloudWatch Logs for system events
- ✅ 7-day retention (within free tier)
- ✅ **Cost:** Completely free for first 12 months

---

## ⚙️ Configuration Changes for Free Tier

### What We **Removed** or **Changed**:

| Component | Original | Free Tier | Reason |
|-----------|----------|-----------|--------|
| **ALB** | ✅ Application Load Balancer | ❌ Removed | Not free-tier eligible ($15-20/month) |
| **EC2 Instance Type** | t3.medium | t3.micro (or t2.micro) | Free tier allows 750 hrs/month t3.micro |
| **EC2 Count** | 2 (backend + frontend) | 2 (backend + frontend) | Both count toward shared 750 hr pool |
| **RDS Instance Class** | db.t3.micro | db.t3.micro | Same, but... |
| **RDS Storage** | 20 GB | 20 GB | Same, FREE for first 12 mo |
| **RDS IOPS** | 3000 iops | ❌ Removed | IOPS costs $0.02/GB/month; use gp3 |
| **RDS Multi-AZ** | false | false | Stays false (Multi-AZ would cost $50+) |
| **NAT Gateway** | 2 (one per AZ) | ❌ Removed for now | Each NAT costs $0.045/GB data transfer + $32/month |
| **Data Transfer** | Unlimited | ⚠️ 100 GB/month free | After 100 GB: $0.09/GB (rare unless viral) |
| **Elastic IPs** | 2 (both attached) | 1 (attached) | 1st free; 2nd = $0.005/hour if unattached |

### Key Optimizations:

1. **Remove ALB** – Use EC2 security groups directly; access via Elastic IP + DNS
2. **Single NAT Gateway** – Or none; EC2 can reach internet directly if needed
3. **t3.micro EC2** – 1 vCPU, 1 GB RAM (enough for Nuxt + Docker)
4. **t3.micro RDS** – Tiny database, suitable for dev/testing
5. **1 Elastic IP** – Backend instance only; frontend is static on S3
6. **CloudFront + S3** – Best free-tier option for static frontend distribution

---

## 💰 Beyond 12 Months: Estimated Monthly Cost

After the free tier expires, here's what you'd pay if running continuously:

| Service | Cost/Month | Notes |
|---------|-----------|-------|
| **EC2 (2x t3.micro)** | ~$15 | $0.0104/hour × 730 hours/month × 2 instances |
| **RDS (db.t3.micro)** | ~$20 | $0.018/hour × 730 hours, plus storage |
| **S3 Storage (5 GB)** | <$1 | $0.023/GB × 5 GB = $0.12 |
| **CloudFront** | ~$5 | Typical 50-100 GB/month egress × $0.085 |
| **Data Transfer Out** | ~$5-10 | VPC NAT + cross-region if applicable |
| **Logs (CloudWatch)** | ~$1 | 7-day retention |
| **IP Address (if unused)** | $0 | (First one stays free; additional = $3.60/month) |
| **Misc (route53, etc.)** | <$1 | |
| **---** | **---** | |
| **TOTAL** | **~$45-55/month** | Budget for day-after-free-tier expiry |

**Way to optimize post-free-tier:**
- Stop EC2 instances when not in use → Save 50%
- Use Reserved Instances → Save 30-50% more
- Switch to Lightsail for fixed monthly cost (~$5-10)

---

## 🚀 Deployment Steps

### Step 1: Update Terraform Variables (Optional)

Edit `aws/terraform.tfvars`:
```hcl
aws_region           = "us-east-1"    # Free tier available
project_name         = "concert"
environment          = "dev"
db_allocated_storage = 20             # FREE tier: 20 GB included
ec2_instance_type    = "t3.micro"     # FREE tier: 750 hrs/month
enable_alb           = false           # Disable ALB (not free)
enable_nat_gateway   = false           # Optional: save $ if not needed
```

### Step 2: Deploy Using Makefile

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Plan free-tier deployment
make free-tier-plan

# Review the plan (should include S3, CloudFront, RDS, EC2, but NOT ALB)

# Apply free-tier deployment
make free-tier-apply
```

### Step 3: After Deployment

- Get CloudFront domain: `terraform output -raw cloudfront_domain_name`
- Get EC2 backend IP: `terraform output -raw backend_ec2_eip`
- Get RDS endpoint: `terraform output -raw rds_endpoint`
- Sync frontend files to S3: `make s3-sync`
- Invalidate CloudFront cache: `make cf-invalidate`

### Step 4: Access Your Application

```
Frontend: https://<cloudfront-domain-name>
Backend:  http://<backend-ec2-eip>:8080/api
Database: mysql -h <rds-endpoint> -u concert_user -p
```

---

## ⚠️ Free Tier Usage Alerts

### Monitor These Metrics:

1. **EC2 Hours** – Reset monthly; max 750 hrs = 2 instances running 24/7 for full month
   - 1 instance running 24/7 = 730 hrs/month → Within limit ✅
   - 2 instances running 24/7 = 1,460 hrs/month → OVER limit ❌

2. **Data Transfer Out** – Max 100 GB free/month
   - Frontend (S3/CloudFront): ~0-10 GB/month (static files are small)
   - Backend API: Depends on traffic; usually <10 GB
   - Keep an eye if traffic spikes

3. **NAT Gateway** – Costs if enabled
   - If instances need outbound internet, use EC2 security group + VPC route to IGW instead

4. **RDS Storage** – Max 20 GB free/month
   - Monitor with: `df -h` inside RDS or CloudWatch metrics

### Set Up AWS Budgets Alert:

```bash
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file:///tmp/budget.json \
  --notifications-with-subscribers file:///tmp/notifications.json
```

Or use AWS Console: **Billing & Cost Management > Budgets > Create Budget > Set alert at $1/month**

---

## 🔒 Security Notes for Free Tier

1. **Do NOT** expose RDS to internet; keep it in private subnets
2. **EC2** instances are in public subnets; use strong SSH keys and security groups
3. **S3 Bucket** is public for website; frontend files are static (safe)
4. **CloudFront** is a read-only CDN; safe to expose

---

## 📞 Troubleshooting Free Tier Issues

### Issue: "Quota exceeded" or "You have exceeded your service quota"

**Solution:**
- Check **AWS Service Quotas** console
- Request quota increase (instant for most)
- Or switch to `t2.micro` if `t3.micro` unavailable

### Issue: "This AWS account does not support creating load balancers"

**Solution:**
- ALB not available in your account
- Using EC2 directly works fine (this guide avoids ALB anyway)

### Issue: "iops or storage throughput for mysql < 400GB"

**Solution:**
- This guide sets `db_allocated_storage = 20` (no iops)
- Already resolved for free tier

### Issue: RDS high availability needed

**Solution:**
- Multi-AZ adds $50+/month; not in free tier
- Use automated snapshots for backup (included)
- Or switch to DynamoDB (free-tier available)

---

## 📈 Cost Monitoring Setup

### 1. Enable Detailed Billing

```bash
# Enable Cost & Usage Reports in AWS Console
# Billing & Cost Management > Cost & Usage Reports > Create report
```

### 2. Use AWS Cost Explorer

- **AWS Console** > **Cost Management** > **Cost Explorer**
- Set alert at $5/month to catch any surprises

### 3. CLI Monitoring

```bash
# Check current costs (last 30 days)
aws ce get-cost-and-usage \
  --time-period Start=2025-09-30,End=2025-10-30 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE

# Forecast next month
aws ce get-forecast \
  --time-period Start=2025-11-01,End=2025-11-30 \
  --metric UNBLENDED_COST \
  --granularity MONTHLY \
  --forecast-type PROJECTED
```

---

## 🎓 Next Steps

1. ✅ Deploy infrastructure: `make free-tier-apply`
2. ✅ Sync frontend: `make s3-sync`
3. ✅ Verify via CloudFront domain
4. ✅ Set up billing alerts
5. ✅ Monitor usage in AWS Console
6. 📚 [AWS Free Tier FAQ](https://aws.amazon.com/free/faq/)

---

## 📚 Reference Links

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 Free Tier Details](https://aws.amazon.com/ec2/pricing/on-demand/)
- [RDS Free Tier Eligibility](https://aws.amazon.com/rds/pricing/free-tier/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [Cost Management Best Practices](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html)

---

**Last Updated:** October 30, 2025  
**Author:** GitHub Copilot  
**Status:** Ready for Free Tier Deployment ✅

