# 🆓 AWS Free Tier Architecture Design
## Singapore Region (ap-southeast-1) - Concert Platform

---

## 📊 **Current Infrastructure vs Free Tier Optimized**

### **Free Tier Limits (12 months + Always Free)**

| Service | Free Tier Limit | Current Usage | Optimization Needed |
|---------|----------------|---------------|---------------------|
| **S3** | 5 GB storage, 20,000 GET, 2,000 PUT | 3 buckets | ✅ Within limits |
| **Lambda** | 1M requests/month, 400,000 GB-seconds | 1 function (128MB) | ✅ Within limits |
| **API Gateway** | 1M HTTP requests/month | HTTP API v2 | ✅ Within limits (HTTP is free!) |
| **CloudFront** | 1 TB data transfer OUT/month | ❌ NOT DEPLOYED | ⚠️ NEED TO ADD |
| **RDS MySQL** | 750 hrs/month db.t3.micro (single-AZ) | db.t3.micro ❌ Multi-AZ OFF | ⚠️ MUST DISABLE Multi-AZ |
| **ElastiCache** | ❌ NOT IN FREE TIER | cache.t3.micro | 💰 $0.017/hour (~$12/month) |
| **DynamoDB** | 25 GB storage, 25 WCU, 25 RCU | 10 tables | ✅ Within limits |
| **SNS** | 1M publishes/month | 5 topics | ✅ Within limits |
| **SQS** | 1M requests/month | 5 queues | ✅ Within limits |
| **CloudWatch** | 10 custom metrics, 5GB ingestion | Multiple log groups | ✅ Within limits |
| **Secrets Manager** | 30-day free trial only | 2 secrets | 💰 $0.40/month/secret |
| **EC2** | 750 hrs/month t2.micro/t3.micro | Not deployed yet | ✅ Can use for backend |

---

## 🎯 **FREE TIER OPTIMIZED ARCHITECTURE**

### **1. Storage Layer - S3 + CloudFront (100% FREE)**

```
┌─────────────────────────────────────────────────────────────┐
│  CLOUDFRONT CDN (1 TB/month FREE)                          │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Edge Locations (Low Latency Globally)             │    │
│  │  - Cache TTL: 86400s (1 day) for images           │    │
│  │  - HTTPS only (Free SSL with ACM)                  │    │
│  │  - Gzip compression enabled                        │    │
│  └────────────────────────────────────────────────────┘    │
│                         ↓                                   │
│  ┌────────────────────────────────────────────────────┐    │
│  │  S3 ORIGIN (5 GB storage FREE)                     │    │
│  │  ┌──────────────────┬──────────────────┐          │    │
│  │  │ Event Pictures   │  User Avatars    │          │    │
│  │  │ - Public read    │  - Public read   │          │    │
│  │  │ - Versioning ON  │  - Lifecycle     │          │    │
│  │  │ - AES-256        │  - AES-256       │          │    │
│  │  └──────────────────┴──────────────────┘          │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**CloudFront Benefits:**
- ✅ **1 TB/month data transfer OUT** (vs 100 GB from S3)
- ✅ **10M HTTP/HTTPS requests/month** 
- ✅ **Free SSL certificates** (AWS Certificate Manager)
- ✅ **Faster global delivery** (caching at edge)
- ✅ **Reduces S3 GET requests** (counts against 20k limit)

---

### **2. Upload Flow - API Gateway + Lambda (100% FREE)**

```
┌──────────────────────────────────────────────────────────────┐
│  CLIENT (Frontend)                                           │
└──────────────┬───────────────────────────────────────────────┘
               │ 1. Request presigned URL
               ↓
┌──────────────────────────────────────────────────────────────┐
│  API GATEWAY HTTP API (1M requests/month FREE)               │
│  POST /upload/event-picture                                  │
│  POST /upload/avatar                                         │
└──────────────┬───────────────────────────────────────────────┘
               │ 2. Invoke Lambda
               ↓
┌──────────────────────────────────────────────────────────────┐
│  LAMBDA FUNCTION (1M invocations FREE)                       │
│  - Runtime: Python 3.11                                      │
│  - Memory: 128 MB (cheapest)                                 │
│  - Timeout: 3 seconds                                        │
│  - Generates presigned S3 URLs (PUT)                         │
└──────────────┬───────────────────────────────────────────────┘
               │ 3. Return presigned URL
               ↓
┌──────────────────────────────────────────────────────────────┐
│  CLIENT                                                      │
│  4. PUT file directly to S3 using presigned URL              │
└──────────────────────────────────────────────────────────────┘
```

**Why HTTP API (not REST API)?**
- ✅ **Up to 70% cheaper** than REST API
- ✅ **1M requests/month FREE** (REST API charges after free tier)
- ✅ Built-in CORS support
- ✅ Simpler, faster (no API keys, usage plans needed)

---

### **3. Database Layer - Optimized for Free Tier**

```
┌──────────────────────────────────────────────────────────────┐
│  RDS MySQL 8.0.39 (FREE TIER: 750 hrs/month)                │
│  - Instance: db.t3.micro (1 vCPU, 1 GB RAM)                 │
│  - Storage: 20 GB gp3 (FREE up to 20 GB)                    │
│  - Single-AZ ONLY (Multi-AZ costs $$)                       │
│  - Backup: 20 GB automated backups FREE                     │
│  - Region: ap-southeast-1                                   │
└──────────────────────────────────────────────────────────────┘
                         ↕
┌──────────────────────────────────────────────────────────────┐
│  DynamoDB (ALWAYS FREE: 25 GB, 25 WCU/RCU)                  │
│  - Use for sessions, caching, real-time data                │
│  - On-demand pricing (better for dev)                       │
│  - Point-in-time recovery: $0.20/GB/month                   │
└──────────────────────────────────────────────────────────────┘
```

**⚠️ CRITICAL: ElastiCache NOT in Free Tier**
- **Current:** cache.t3.micro = **~$12/month**
- **Solution:** Use **DynamoDB** for session storage instead
  - Store sessions in DynamoDB table
  - 25 GB storage FREE forever
  - 25 WCU/RCU = ~1M requests/month

---

### **4. Backend Compute - EC2 Free Tier**

```
┌──────────────────────────────────────────────────────────────┐
│  EC2 INSTANCE (750 hrs/month FREE)                          │
│  - Type: t3.micro (2 vCPU, 1 GB RAM)                        │
│  - OS: Amazon Linux 2023 (no license cost)                  │
│  - Storage: 30 GB gp3 EBS (30 GB free)                      │
│  - Region: ap-southeast-1                                   │
│  ┌────────────────────────────────────────────────┐         │
│  │  Spring Boot Application                       │         │
│  │  - Port 8080                                   │         │
│  │  - Java 21 OpenJDK (free)                      │         │
│  │  - Maven build                                 │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────────────────────────────────────────────┘
```

**Free Tier Details:**
- ✅ **750 hours/month** = 31 days × 24 hours (1 instance running 24/7)
- ✅ **30 GB EBS storage**
- ✅ **1 GB snapshot storage**
- ✅ **15 GB data transfer OUT** to internet

---

## 💰 **COST BREAKDOWN (Monthly Estimate)**

### **Completely FREE Services (within limits):**
| Service | Free Tier | Monthly Cost |
|---------|-----------|--------------|
| S3 (5 GB storage) | ✅ | **$0.00** |
| CloudFront (1 TB out) | ✅ | **$0.00** |
| Lambda (1M requests) | ✅ | **$0.00** |
| API Gateway HTTP | ✅ | **$0.00** |
| RDS MySQL (db.t3.micro, single-AZ) | ✅ | **$0.00** |
| DynamoDB (25 GB) | ✅ | **$0.00** |
| EC2 (t3.micro, 750 hrs) | ✅ | **$0.00** |
| SNS (1M publishes) | ✅ | **$0.00** |
| SQS (1M requests) | ✅ | **$0.00** |
| CloudWatch (10 metrics) | ✅ | **$0.00** |
| EBS (30 GB) | ✅ | **$0.00** |

### **Paid Services (NOT in free tier):**
| Service | Reason | Monthly Cost |
|---------|--------|--------------|
| ❌ ElastiCache Redis | Not in free tier | **~$12.00** |
| ⚠️ Secrets Manager (2 secrets) | Only 30-day trial | **$0.80** |
| Elastic IP (if not attached) | Idle IP charge | **$3.60** |

### **TOTAL COST OPTIONS:**

**Option 1: Zero Cost (Pure Free Tier)**
- Remove ElastiCache, use DynamoDB for sessions
- Store credentials in EC2 environment variables (not Secrets Manager)
- Use attached Elastic IP only
- **Total: $0.00/month** ✅

**Option 2: Minimal Cost (Best for Dev)**
- Keep ElastiCache for Redis features
- Use Secrets Manager for secure credential storage
- **Total: ~$12.80/month** 💰

**Option 3: Recommended Production-Ready**
- ElastiCache Redis (cache.t3.micro)
- Secrets Manager (2 secrets)
- CloudFront (within 1TB free tier)
- **Total: ~$12.80/month** 💰

---

## 🏗️ **RECOMMENDED FREE TIER ARCHITECTURE**

```
                    ┌─────────────────┐
                    │   CLOUDFRONT    │ (1 TB/month FREE)
                    │  CDN + SSL      │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ↓                   ↓                   ↓
    ┌────────┐         ┌─────────┐        ┌──────────┐
    │  S3    │         │   API   │        │   EC2    │
    │ Images │         │ Gateway │────────│ Backend  │
    └────────┘         └─────────┘        │ t3.micro │
         ↑                   │             └────┬─────┘
         │                   ↓                  │
         │              ┌─────────┐             │
         └──────────────│ Lambda  │             │
                        │ Presign │             │
                        └─────────┘             │
                                                ↓
                    ┌────────────────────────────────┐
                    │         Data Layer             │
                    ├────────────────┬───────────────┤
                    │  RDS MySQL     │  DynamoDB     │
                    │  (relational)  │  (sessions)   │
                    └────────────────┴───────────────┘
```

---

## 📋 **IMPLEMENTATION CHECKLIST**

### **Phase 1: Add CloudFront (FREE)**
- [ ] Create CloudFront distribution for S3 buckets
- [ ] Point origins to `event-pictures` and `user-avatars` buckets
- [ ] Enable Gzip compression
- [ ] Set cache behaviors (1 day TTL for images)
- [ ] Request free SSL certificate from ACM
- [ ] Update frontend to use CloudFront URLs

### **Phase 2: Optimize RDS (FREE)**
- [ ] ⚠️ **DISABLE Multi-AZ** on RDS instance (saves $$)
- [ ] Keep db.t3.micro instance (FREE tier eligible)
- [ ] Set backup window to low-traffic hours
- [ ] Enable CloudWatch alarms (10 metrics FREE)

### **Phase 3: Replace ElastiCache with DynamoDB (FREE)**
- [ ] Create DynamoDB table: `concert-sessions-dev`
- [ ] Configure Spring Session to use DynamoDB
- [ ] Migrate session data structure
- [ ] Update backend dependencies
- [ ] **DELETE ElastiCache cluster** (saves $12/month)

### **Phase 4: Deploy Backend to EC2 (FREE)**
- [ ] Launch t3.micro instance (750 hrs/month FREE)
- [ ] Install Java 21 OpenJDK
- [ ] Configure security groups (port 8080, 22)
- [ ] Deploy Spring Boot JAR
- [ ] Set environment variables for DB/S3
- [ ] Configure systemd service for auto-start

### **Phase 5: Cost Optimization**
- [ ] Monitor S3 storage (stay under 5 GB)
- [ ] Monitor API Gateway requests (stay under 1M/month)
- [ ] Monitor Lambda invocations (stay under 1M/month)
- [ ] Set up CloudWatch billing alarms
- [ ] Review AWS Cost Explorer weekly

---

## 🔧 **TERRAFORM CHANGES NEEDED**

### **1. Add CloudFront Distribution**
Create `aws/cloudfront.tf`:
```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"  # Use only North America & Europe (cheaper)
  
  origin {
    domain_name = aws_s3_bucket.event_pictures.bucket_regional_domain_name
    origin_id   = "S3-event-pictures"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }
  
  origin {
    domain_name = aws_s3_bucket.user_avatars.bucket_regional_domain_name
    origin_id   = "S3-user-avatars"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }
  
  default_cache_behavior {
    target_origin_id       = "S3-event-pictures"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 86400  # 1 day
    max_ttl     = 31536000  # 1 year
    compress    = true
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  comment = "OAI for Concert S3 buckets"
}
```

### **2. Modify RDS for Free Tier**
Update `aws/rds.tf`:
```hcl
resource "aws_db_instance" "concert" {
  # ... existing config ...
  
  # ⚠️ CRITICAL: Disable Multi-AZ for FREE tier
  multi_az = false  # Change from true
  
  # Already FREE tier compliant:
  instance_class    = "db.t3.micro"  # ✅ FREE
  allocated_storage = 20             # ✅ FREE (up to 20 GB)
  engine_version    = "8.0.39"       # ✅ FREE
}
```

### **3. Add DynamoDB Session Table**
Update `aws/dynamodb.tf`:
```hcl
resource "aws_dynamodb_table" "sessions" {
  name         = "${var.project_name}-sessions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"  # Better for low traffic
  hash_key     = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }
  
  tags = {
    Name        = "Concert Sessions"
    Environment = var.environment
  }
}
```

---

## 📊 **MONITORING & ALERTS (FREE)**

### **CloudWatch Alarms (10 Custom Metrics FREE)**
1. **RDS CPU > 80%** → Alert
2. **RDS Storage < 2 GB** → Alert
3. **Lambda errors > 10** → Alert
4. **API Gateway 5xx > 5** → Alert
5. **S3 storage > 4.5 GB** → Alert (90% of 5 GB limit)
6. **DynamoDB throttles > 0** → Alert
7. **EC2 CPU > 80%** → Alert
8. **EC2 Network Out > 1 GB/day** → Alert (track towards 15 GB/month limit)
9. **Billing > $5** → Alert
10. **Estimated charges > $10** → Critical alert

---

## 🎯 **PERFORMANCE OPTIMIZATION**

### **S3 + CloudFront Best Practices**
1. **Image Optimization:**
   - Resize images before upload (Lambda@Edge if needed)
   - Use WebP format (smaller size)
   - Max 1 MB per image
   
2. **CloudFront Caching:**
   - Set `Cache-Control: max-age=31536000` for immutable files
   - Use versioned filenames (`avatar-v123.jpg`)
   - Enable Gzip/Brotli compression

3. **S3 Lifecycle Rules:**
   - Move old event pictures to S3 Glacier after 90 days (cheaper)
   - Delete incomplete multipart uploads after 7 days

### **Lambda Optimization (Stay in FREE tier)**
1. **Minimize cold starts:**
   - Keep code small (<1 MB zipped)
   - Use Python 3.11 (fastest cold start)
   - Set reserved concurrency = 1 (prevent burst costs)

2. **Reduce execution time:**
   - Generate presigned URLs only (don't process files)
   - Timeout = 3 seconds (adequate)
   - Memory = 128 MB (cheapest)

3. **Monitor invocations:**
   - If approaching 1M/month, implement client-side caching
   - Cache presigned URLs for 50 minutes (they're valid for 1 hour)

---

## 🚨 **COST ALERTS & SAFEGUARDS**

### **AWS Budget Setup**
```bash
# Set monthly budget alert
aws budgets create-budget --account-id YOUR_ACCOUNT_ID --budget '{
  "BudgetName": "FreeTier-Monthly",
  "BudgetLimit": {
    "Amount": "1.00",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}'
```

### **What to Monitor Weekly:**
1. **S3 Storage:** `aws s3 ls s3://bucket-name --recursive --summarize`
2. **Lambda Invocations:** Check CloudWatch metrics
3. **API Gateway Requests:** Check CloudWatch metrics
4. **RDS Hours:** Ensure only 1 instance running
5. **Data Transfer:** Monitor CloudFront and S3 outbound data

---

## 🎓 **FREE TIER LIMITS SUMMARY**

| Service | Limit | How to Stay Within |
|---------|-------|-------------------|
| S3 Storage | 5 GB | Limit user uploads, compress images |
| S3 GET | 20,000/month | Use CloudFront (reduces S3 GETs) |
| S3 PUT | 2,000/month | ~67 uploads/day (reasonable for dev) |
| CloudFront | 1 TB out | ~33 GB/day (very generous) |
| Lambda | 1M requests | ~33k/day (enough for 1000 users/day) |
| API Gateway | 1M requests | Use caching, combine requests |
| RDS | 750 hrs/month | Run only 1 instance |
| EC2 | 750 hrs/month | Run only 1 instance |
| DynamoDB | 25 GB storage | Clean up old sessions regularly |

---

## ✅ **NEXT STEPS**

1. **Immediate (Today):**
   - Review current deployment status
   - Disable RDS Multi-AZ if enabled
   - Check ElastiCache costs in billing

2. **This Week:**
   - Add CloudFront distribution
   - Create DynamoDB sessions table
   - Deploy backend to EC2 t3.micro

3. **This Month:**
   - Migrate from ElastiCache to DynamoDB
   - Implement cost monitoring dashboards
   - Load test within free tier limits

---

## 📚 **REFERENCES**

- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [API Gateway HTTP vs REST](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html)
- [DynamoDB Session Storage](https://docs.spring.io/spring-session/docs/current/reference/html5/#httpsession-dynamodb)
- [S3 Performance Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/optimizing-performance.html)

---

**Last Updated:** October 31, 2025  
**Region:** ap-southeast-1 (Singapore)  
**Target:** $0.00/month (100% Free Tier)
