# Concert Platform - Optimized for $180 Free Credits
## Production-Grade Architecture with Auto-Scaling

**Budget**: $180 USD (Free Credits)  
**Target**: 7-9 months of full production use  
**Region**: us-east-1  
**Date**: October 31, 2025

---

## 🎯 RECOMMENDED ARCHITECTURE

### Smart Free Tier + Credits = $20-25/month

**This gives you 7-9 months of runtime!**

---

## 🏗️ Architecture Design

```
Users
  ↓
CloudFront (CDN + HTTPS)
  ↓
Application Load Balancer
  ↓
┌─────────────────────────────────────┐
│    EC2 Auto Scaling Group           │
│    (min: 1, max: 3)                 │
│    t3.small instances               │
│    Spring Boot Backend              │
└─────────────────────────────────────┘
  ↓                 ↓
RDS MySQL      S3 Buckets
(db.t3.micro)   (versioned)
  ↓                 ↓
Cognito         Lambda
(Auth)        (Processing)
```

---

## 💰 Cost Breakdown

### Monthly Estimate: $22-28

| Service | Configuration | Free Tier | You Pay | Notes |
|---------|---------------|-----------|---------|-------|
| **EC2** | 1 x t3.small (can scale to 3) | 750h t2.micro | $15/mo | Main backend |
| **RDS MySQL** | db.t3.micro Single-AZ | 750h free | $0/mo | Free tier! |
| **ALB** | Application Load Balancer | No free tier | $16/mo | Auto-scaling |
| **S3** | 50GB storage | 5GB free | $1.04/mo | File storage |
| **CloudFront** | 50GB transfer/month | 50GB free | $0/mo | Free tier! |
| **Cognito** | 5,000 active users/month | 50,000 free | $0/mo | Free tier! |
| **Lambda** | 1M requests @ 512MB | 1M free | $0/mo | Free tier! |
| **API Gateway** | 1M requests | 1M free | $0/mo | Free tier! |
| **CloudWatch** | Basic monitoring | Limited free | $2/mo | Logs |
| **Secrets Manager** | 2 secrets | 30 days free | $0.80/mo | Credentials |
| **VPC** | Subnets, IGW, SG | Free | $0/mo | Network |
| **NAT Gateway** | ❌ SKIP | - | $0/mo | Use VPC endpoints |
| **Data Transfer** | Minimal | 1GB free | $1/mo | Internet out |
| **TOTAL** | | | **~$36/mo** | **5 months** |

---

## ⚡ Further Optimizations

### Remove ALB = $20/month = **9 months!**

Instead of ALB, use:
- CloudFront → EC2 directly
- Manual scaling (add instances when needed)
- Still get auto-healing with Auto Scaling Group

### New Cost: $20/month

| Service | Cost |
|---------|------|
| EC2 t3.small | $15 |
| S3 (45GB) | $1 |
| CloudWatch | $2 |
| Secrets Manager | $0.80 |
| Data Transfer | $1 |
| **TOTAL** | **$19.80** |

**Runtime: 9+ months!** 🎉

---

## 🚀 What You Get

### Infrastructure
- ✅ **VPC** with public/private subnets (multi-AZ ready)
- ✅ **EC2 Auto Scaling Group** (1-3 instances)
- ✅ **RDS MySQL** (db.t3.micro, automated backups)
- ✅ **S3 buckets** (event pictures, user avatars)
- ✅ **CloudFront CDN** (global content delivery)
- ✅ **Cognito** (user authentication)
- ✅ **Lambda functions** (file processing)
- ✅ **API Gateway** (REST endpoints)
- ✅ **CloudWatch** (monitoring, logs, alarms)
- ✅ **IAM roles** (security)
- ✅ **Secrets Manager** (database credentials)

### Features
- ✅ Auto-scaling (manual or ALB-based)
- ✅ High availability (multi-AZ capable)
- ✅ HTTPS everywhere (CloudFront SSL)
- ✅ User authentication (Cognito)
- ✅ File uploads (S3 presigned URLs)
- ✅ Database backups (automated)
- ✅ Monitoring & alerts
- ✅ Docker support (ECR optional)

### Scaling Path
- **Start**: 1 EC2 instance ($20/month)
- **Grow**: Add ALB + 3 instances ($36/month)
- **Enterprise**: Add NAT, ElastiCache, etc. ($100+/month)

---

## 📋 Deployment Plan

### Phase 1: Core Infrastructure (Day 1)
```hcl
✅ VPC (10.0.0.0/16)
✅ Public subnets (2 AZs)
✅ Private subnets (2 AZs)
✅ Internet Gateway
✅ Route Tables
✅ Security Groups
```

### Phase 2: Database (Day 1)
```hcl
✅ RDS MySQL (db.t3.micro)
✅ DB subnet group
✅ Secrets Manager (credentials)
✅ Automated backups
```

### Phase 3: Compute (Day 2)
```hcl
✅ EC2 Launch Template
✅ Auto Scaling Group (1-3 instances)
✅ User data (install app)
✅ IAM instance profile
```

### Phase 4: Storage & CDN (Day 2)
```hcl
✅ S3 buckets (event-pictures, user-avatars)
✅ S3 bucket policies
✅ CloudFront distribution
✅ SSL certificate (ACM)
```

### Phase 5: Authentication (Day 3)
```hcl
✅ Cognito User Pool
✅ Cognito App Client
✅ User attributes config
✅ IAM roles for Cognito
```

### Phase 6: Serverless (Day 3)
```hcl
✅ Lambda functions (presigned URLs)
✅ API Gateway REST API
✅ Lambda permissions
✅ VPC endpoints (optional)
```

### Phase 7: Monitoring (Day 4)
```hcl
✅ CloudWatch Log Groups
✅ CloudWatch Alarms
✅ SNS topics (alerts)
✅ CloudWatch dashboards
```

---

## 🎯 Cost Scenarios

### Scenario 1: Minimal ($19/month)
- 1 EC2 t3.small
- No ALB (CloudFront → EC2)
- Free tier RDS
- **Runtime: 9.5 months**

### Scenario 2: Balanced ($28/month)
- 1 EC2 t3.small
- Application Load Balancer
- Auto Scaling ready
- **Runtime: 6.4 months**

### Scenario 3: Full Production ($50/month)
- 2 EC2 t3.small
- ALB + NAT Gateway
- Multi-AZ everything
- **Runtime: 3.6 months**

---

## ✅ RECOMMENDATION

Deploy **Scenario 1** now:
- Cost: $19-20/month
- Runtime: 9+ months
- Includes ALL features except ALB

**Can upgrade to ALB later when traffic increases!**

---

**Ready to deploy?**

Reply **"yes"** and I'll:
1. Generate all Terraform files
2. Create deployment scripts
3. Deploy infrastructure
4. Provide configuration guide
5. Setup monitoring

**Estimated deployment time: 15-20 minutes** ⏱️
