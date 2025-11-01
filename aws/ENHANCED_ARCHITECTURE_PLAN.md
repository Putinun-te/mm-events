# 🚀 Enhanced Concert Platform Architecture

## 💰 Budget Analysis

**Current Status:**
- Credits Remaining: **$172.85 USD**
- Days Remaining: **181 days** (until Apr 29, 2026)
- Current Monthly Cost: **$7.15**
- Available Budget: **~$172.85 / 6 months = $28.80/month**

**Current Infrastructure Cost: $52/month**
- ❌ This exceeds your budget!
- ✅ **Solution**: Optimize to $25-28/month

---

## 🎯 Enhanced Architecture with Requested Services

### Service Stack:
1. ✅ **Elastic Beanstalk** - Application deployment
2. ✅ **ElastiCache** - Redis caching
3. ✅ **CloudFormation** - Infrastructure as Code
4. ✅ **CloudWatch** - Monitoring & logging
5. ✅ **Cognito** - Already deployed ✓
6. ✅ **S3** - Already deployed ✓
7. ✅ **CI/CD**: GitHub Actions + AWS CodePipeline

---

## 📊 Updated Cost Breakdown

### Option 1: Elastic Beanstalk Approach ($24/month)
| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| **Elastic Beanstalk** | $0 | FREE (only pay for resources) |
| EC2 t3.micro (1 instance) | $7.59 | Beanstalk managed |
| **RDS db.t3.micro** | $0 | FREE tier (12 months) |
| **ElastiCache t3.micro** | $12.41 | Redis for caching |
| **S3** | $0-1 | FREE tier |
| **CloudWatch** | $0 | FREE tier metrics |
| **CodePipeline** | $1 | First pipeline $1/month |
| **NAT Gateway** | $0 | **REMOVED** to save |
| **ALB** | $0 | **Use single instance** |
| **Data Transfer** | $1-2 | Minimal |
| **TOTAL** | **~$22-24/month** | ✅ Under budget! |

### Option 2: Current Auto Scaling + Cache ($28/month)
| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| EC2 t3.small (1 instance) | $15.18 | Current setup |
| **ElastiCache t3.micro** | $12.41 | Redis |
| RDS db.t3.micro | $0 | FREE tier |
| S3 | $0-1 | FREE tier |
| **TOTAL** | **~$28/month** | ✅ Fits budget! |

**Recommendation: Option 1 with Elastic Beanstalk** 🎯

---

## 🏗️ Architecture Comparison

### Current (Manual EC2)
```
Internet → EC2 (Auto Scaling) → RDS MySQL
                ↓
               S3
```

### Enhanced (Elastic Beanstalk)
```
Internet → Elastic Beanstalk → ElastiCache (Redis)
              ↓                      ↓
           RDS MySQL              Application
              ↓
             S3
              ↓
          Cognito (Auth)
              ↓
        CloudWatch (Monitoring)
```

---

## 🔧 Detailed Service Configuration

### 1. Elastic Beanstalk
**Purpose**: Simplified deployment & auto-scaling
- **Environment Type**: Single instance (save cost)
- **Platform**: Java 17 Corretto
- **Instance Type**: t3.micro
- **Features**:
  - Auto-deployment from Git
  - Built-in monitoring
  - Easy rollback
  - Environment variables management

**Cost**: $0 (pay for EC2: $7.59/month)

---

### 2. ElastiCache (Redis)
**Purpose**: Session storage, API caching, performance boost
- **Engine**: Redis 7.x
- **Node Type**: cache.t3.micro
- **Nodes**: 1 (Multi-AZ optional)
- **Use Cases**:
  - Session storage (replace database sessions)
  - API response caching
  - Concert ticket inventory caching
  - User authentication tokens

**Cost**: $12.41/month
**FREE Tier**: 750 hours/month for 12 months (t2.micro only)

---

### 3. CloudFormation
**Purpose**: Infrastructure as Code (better than Terraform for AWS)
- **Templates**: YAML/JSON
- **Features**:
  - Stack management
  - Rollback on failure
  - Change sets
  - Nested stacks

**Cost**: $0 (CloudFormation is FREE)

---

### 4. CloudWatch
**Purpose**: Monitoring, logging, alerts
- **Metrics**: FREE tier
  - 10 custom metrics
  - 10 alarms
  - 5GB log ingestion
- **Dashboards**: Up to 3 FREE
- **Alarms**:
  - High CPU
  - Memory usage
  - Database connections
  - Cache hit rate

**Cost**: $0 (within FREE tier)

---

### 5. Cognito (Already Deployed ✓)
**Current Setup**:
- User Pool: `us-east-1_TpsZkFbqO`
- Client ID: `2089udacia4eoge33fgmm0sbca`
- Features: Email verification, OAuth, MFA

**Cost**: $0 (FREE for <50K MAU)

---

### 6. S3 (Already Deployed ✓)
**Current Buckets**:
- `concert-event-pictures-useast1-123456789012`
- `concert-user-avatars-useast1-123456789012`

**Cost**: $0-1 (FREE tier: 5GB)

---

### 7. CI/CD Pipeline Options

#### Option A: GitHub Actions (FREE) ✅ **RECOMMENDED**
```yaml
Workflow:
1. Push code to GitHub
2. GitHub Actions runs tests
3. Build Docker image
4. Push to ECR (Elastic Container Registry)
5. Deploy to Elastic Beanstalk
```

**Cost**: $0 (FREE for public repos, 2000 min/month private)

#### Option B: AWS CodePipeline
```yaml
Pipeline:
1. CodeCommit (or GitHub webhook)
2. CodeBuild (compile, test)
3. CodeDeploy (deploy to Beanstalk)
```

**Cost**: $1/month (first pipeline)

#### Option C: Hybrid (GitHub + CodePipeline)
```yaml
Best of both worlds:
1. GitHub Actions for build/test
2. CodePipeline for deployment
```

**Cost**: $1/month

**RECOMMENDATION**: GitHub Actions only (FREE) 🎯

---

## 📋 Migration Plan

### Phase 1: Add ElastiCache & CloudWatch (Today)
```bash
# Add to existing infrastructure
- Create ElastiCache Redis cluster
- Set up CloudWatch dashboards
- Configure alarms
```
**Cost Impact**: +$12/month
**Total**: $52 + $12 = $64/month ⚠️ Over budget!

### Phase 2: Optimize Current Setup (Recommended First)
```bash
# Remove expensive components
- Remove NAT Gateway (-$32/month)
- Downgrade EC2 to t3.micro (-$8/month)
- Keep everything else
```
**Cost Impact**: $52 - $40 = **$12/month** ✅

### Phase 3: Add ElastiCache
```bash
# Add caching
- ElastiCache t3.micro (+$12/month)
```
**Total**: $12 + $12 = **$24/month** ✅

### Phase 4: Migrate to Elastic Beanstalk (Optional)
```bash
# Replace manual EC2 with Beanstalk
- Simpler management
- Auto-deployment
- Same cost
```
**Total**: **$24/month** ✅

---

## 🚀 Immediate Action Plan

### Step 1: Optimize Current Infrastructure
```bash
# Remove NAT Gateway to save $32/month
cd /Users/putinan/development/DevOps/develop/aws

# Edit networking.tf - comment out NAT Gateway
# Then apply changes
terraform apply
```

### Step 2: Add ElastiCache
Create `elasticache.tf`:
```hcl
resource "aws_elasticache_subnet_group" "redis" {
  name       = "concert-redis-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "concert-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
}
```

### Step 3: Add CloudWatch Dashboard
Create `cloudwatch.tf`:
```hcl
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "concert-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization"],
            ["AWS/RDS", "CPUUtilization"],
            ["AWS/ElastiCache", "CPUUtilization"]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "CPU Usage"
        }
      }
    ]
  })
}
```

### Step 4: Set Up GitHub Actions CI/CD
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Build and deploy
        run: |
          # Build your application
          # Deploy to Elastic Beanstalk or EC2
```

---

## 📊 Final Cost Comparison

### Current Setup
- **Monthly**: $52
- **6 months**: $312 ❌ Exceeds $172.85 budget

### Optimized Setup (Recommended)
- **Monthly**: $24
- **6 months**: $144 ✅ Under budget!
- **Remaining**: $28.85 buffer

### Services Included:
✅ Elastic Beanstalk (or EC2 t3.micro)
✅ ElastiCache Redis
✅ RDS MySQL (FREE tier)
✅ S3 (FREE tier)
✅ Cognito (FREE tier)
✅ CloudWatch (FREE tier)
✅ CloudFormation (FREE)
✅ GitHub Actions CI/CD (FREE)

---

## 🎯 Recommended Next Steps

1. **Immediate** (Today):
   - Remove NAT Gateway → Save $32/month
   - Add ElastiCache → Add $12/month
   - Net: **$20/month savings**

2. **This Week**:
   - Set up CloudWatch dashboards (FREE)
   - Configure CloudWatch alarms (FREE)
   - Create GitHub Actions workflow (FREE)

3. **Optional** (Later):
   - Migrate to Elastic Beanstalk for easier management
   - Convert Terraform to CloudFormation
   - Add WAF for security ($5-10/month if needed)

---

## 🛠️ Implementation Files

I'll create the following files:
1. `elasticache.tf` - Redis configuration
2. `cloudwatch.tf` - Monitoring & alarms
3. `cloudformation-template.yaml` - Alternative to Terraform
4. `.github/workflows/deploy.yml` - CI/CD pipeline
5. `optimize-costs.sh` - Script to remove NAT Gateway

Ready to proceed? 🚀
