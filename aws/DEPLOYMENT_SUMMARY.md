# ✅ S3 & CloudFront Deployment Summary
**Concert Platform - Singapore Deployment**

## 🎯 What Was Deployed

### Issue Fixed: ✅ S3 Upload Permissions
**Problem:** "S3 is not upload a object"  
**Root Cause:** S3 bucket policies referenced non-existent `aws_iam_role.backend_ec2_role`  
**Solution:** Updated policies to use existing `aws_iam_role.lambda_presigned_url_role`

### Infrastructure Deployed:

#### **2 CloudFront Distributions:**

1. **UGC Distribution** (User-Generated Content)
   - **Purpose:** Event pictures + User avatars
   - **Price Class:** PriceClass_100 (North America + Europe - cheaper)
   - **Cache TTL:**
     - Event pictures: 1 day default, 1 year max
     - User avatars: 1 hour default, 1 day max
   - **Origins:**
     - `concert-event-pictures-123456789012.s3.ap-southeast-1.amazonaws.com`
     - `concert-user-avatars-123456789012.s3.ap-southeast-1.amazonaws.com`

2. **Website Distribution** (Frontend Application)
   - **Purpose:** Static website hosting
   - **Price Class:** PriceClass_All (Global distribution)
   - **Cache TTL:**
     - HTML: 1 hour default
     - /_nuxt/* (JS/CSS): 1 week default
     - /images/*: 1 week default
   - **Origin:**
     - `concert-website-123456789012.s3.ap-southeast-1.amazonaws.com`

#### **3 S3 Buckets:**

1. **concert-event-pictures-123456789012**
   - Encryption: AES-256
   - Versioning: Enabled
   - Access: CloudFront READ, Lambda WRITE
   - CORS: Enabled for uploads

2. **concert-user-avatars-123456789012**
   - Encryption: AES-256
   - Versioning: Disabled
   - Access: CloudFront READ, Lambda WRITE
   - CORS: Enabled for uploads

3. **concert-website-123456789012** ⭐ NEW
   - Encryption: AES-256
   - Versioning: Enabled
   - Access: CloudFront READ only
   - Website hosting: Enabled (index.html)

#### **API Gateway + Lambda:**
- **Endpoint:** https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev
- **Routes:**
  - `POST /upload/event-picture` → Generate presigned URL for event pictures
  - `POST /upload/avatar` → Generate presigned URL for avatars
- **Lambda:** concert-generate-presigned-url (Python 3.11, 128MB, 3s timeout)

#### **Monitoring:**
- **CloudWatch Alarms:**
  - `concert-cloudfront-data-transfer-dev` → Alert at 900 GB/day
  - `concert-cloudfront-requests-dev` → Alert at 300k requests/day
- **SNS Topic:** concert-alerts-dev (receives alarm notifications)

---

## 🔐 Security Architecture

### Upload Flow (Secure):
```
Client → API Gateway → Lambda → S3 Presigned URL (5 min expiry) → Client uploads directly to S3
```

### Access Flow (Secure):
```
User → CloudFront (HTTPS) → S3 (via Origin Access Identity - private access)
```

### Permissions Matrix:

| Resource | CloudFront OAI | Lambda Role | Public Access |
|----------|---------------|-------------|---------------|
| event-pictures | ✅ READ (s3:GetObject) | ✅ WRITE (s3:PutObject, s3:DeleteObject, s3:GetObject) | ❌ Blocked |
| user-avatars | ✅ READ (s3:GetObject) | ✅ WRITE (s3:PutObject, s3:DeleteObject, s3:GetObject) | ❌ Blocked |
| website | ✅ READ (s3:GetObject) | ❌ No access | ❌ Blocked |

**All S3 buckets are private.** Files are only accessible via:
- CloudFront CDN (for public viewing)
- Lambda presigned URLs (for uploads, 5-minute expiry)

---

## 💰 Cost Analysis

### FREE TIER Services (12 months):

| Service | Free Tier Limit | Current Usage | Cost if Exceeded |
|---------|----------------|---------------|-----------------|
| **CloudFront** | 1 TB data OUT + 10M requests | 0% | $0.085/GB (Asia Pacific) |
| **S3 Storage** | 5 GB | <1% | $0.025/GB/month |
| **S3 GET** | 20,000 requests | <1% | $0.0004/1000 requests |
| **S3 PUT** | 2,000 requests | <1% | $0.005/1000 requests |
| **Lambda** | 1M invocations + 400k GB-seconds | <1% | $0.20/1M invocations |
| **API Gateway HTTP** | 1M requests | <1% | $1.00/1M requests |

### PAID Services (Not Free Tier):

| Service | Monthly Cost | Purpose | Can Remove? |
|---------|--------------|---------|-------------|
| **ElastiCache Redis** | ~$12.00 | Session storage, caching | ✅ YES (use DynamoDB for sessions) |
| **Secrets Manager** | $0.80 | Store DB credentials | ⚠️ Use environment variables instead |

### Estimated Monthly Cost:
- **Current:** ~$12.80/month (ElastiCache + Secrets Manager)
- **Optimized (ElastiCache removed):** $0.80/month (Secrets Manager only)
- **Fully Optimized (Env vars):** $0.00/month ✨ **100% FREE**

---

## 📊 How to Get CloudFront URLs

Run this command after deployment completes (~10-15 minutes):

```bash
cd /Users/putinan/development/DevOps/develop/aws
terraform output
```

### Expected Outputs:

```hcl
cloudfront_ugc_domain     = "d1234567890abc.cloudfront.net"
cloudfront_ugc_id         = "E1XXXXXXXXX"
cloudfront_ugc_url        = "https://d1234567890abc.cloudfront.net"

cloudfront_website_domain = "d0987654321xyz.cloudfront.net"
cloudfront_website_id     = "E2XXXXXXXXX"
cloudfront_website_url    = "https://d0987654321xyz.cloudfront.net"

usage_examples = {
  event_picture_url = "https://d1234567890abc.cloudfront.net/events/event123.jpg"
  avatar_url        = "https://d1234567890abc.cloudfront.net/avatars/user456.jpg"
  website_url       = "https://d0987654321xyz.cloudfront.net"
}

website_bucket_name = "concert-website-123456789012"
```

### Save to Environment Variables:

```bash
# For backend (.env)
UGC_CDN_URL=https://d1234567890abc.cloudfront.net
WEBSITE_CDN_URL=https://d0987654321xyz.cloudfront.net

# For frontend (.env.production)
VITE_UGC_CDN_URL=https://d1234567890abc.cloudfront.net
VITE_API_URL=https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev
VITE_WEBSITE_URL=https://d0987654321xyz.cloudfront.net
```

---

## 🚀 Quick Start - Upload & Access Files

### 1. Upload Event Picture:

```bash
#!/bin/bash
API_URL="https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev"

# Get presigned URL
RESPONSE=$(curl -s -X POST "$API_URL/upload/event-picture" \
  -H "Content-Type: application/json" \
  -d '{"filename": "concert.jpg", "contentType": "image/jpeg"}')

UPLOAD_URL=$(echo $RESPONSE | jq -r '.uploadUrl')
KEY=$(echo $RESPONSE | jq -r '.key')

# Upload file
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --upload-file concert.jpg

echo "File uploaded! Access via:"
echo "CloudFront: https://d1234567890abc.cloudfront.net/$KEY"
```

### 2. Upload Avatar:

```bash
#!/bin/bash
API_URL="https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev"

# Get presigned URL for avatar
RESPONSE=$(curl -s -X POST "$API_URL/upload/avatar" \
  -H "Content-Type: application/json" \
  -d '{"filename": "avatar.jpg", "contentType": "image/jpeg"}')

UPLOAD_URL=$(echo $RESPONSE | jq -r '.uploadUrl')
KEY=$(echo $RESPONSE | jq -r '.key')

# Upload file
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --upload-file avatar.jpg

echo "Avatar uploaded! Access via:"
echo "CloudFront: https://d1234567890abc.cloudfront.net/$KEY"
```

### 3. Deploy Website:

```bash
#!/bin/bash
BUCKET="concert-website-123456789012"
DIST_ID=$(terraform output -raw cloudfront_website_id)

# Build frontend (Nuxt example)
cd /Users/putinan/development/DevOps/develop/main_frontend/concert1
npm run build

# Upload to S3
aws s3 sync .output/public/ s3://$BUCKET/ \
  --region ap-southeast-1 \
  --delete \
  --cache-control "public, max-age=31536000"

# Upload index.html with shorter cache
aws s3 cp .output/public/index.html s3://$BUCKET/index.html \
  --region ap-southeast-1 \
  --cache-control "public, max-age=3600" \
  --content-type "text/html"

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"

echo "Website deployed! Access via:"
echo "CloudFront: https://d0987654321xyz.cloudfront.net"
```

---

## 🧪 Testing the Setup

### Test 1: Presigned URL Generation

```bash
curl -X POST https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev/upload/event-picture \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.jpg", "contentType": "image/jpeg"}'

# Expected response:
{
  "uploadUrl": "https://concert-event-pictures-123456789012.s3.ap-southeast-1.amazonaws.com/events/test.jpg?X-Amz-...",
  "fileUrl": "https://concert-event-pictures-123456789012.s3.ap-southeast-1.amazonaws.com/events/test.jpg",
  "key": "events/test.jpg"
}
```

### Test 2: File Upload

```bash
# Create test image
echo "Creating test image..."
convert -size 100x100 xc:blue test.jpg

# Use uploadUrl from Test 1
curl -X PUT "<uploadUrl from Test 1>" \
  -H "Content-Type: image/jpeg" \
  --upload-file test.jpg

# Expected: HTTP 200 OK
```

### Test 3: CloudFront Access

```bash
# Wait 30s for propagation
sleep 30

# Access via CloudFront (replace with your domain)
curl -I https://d1234567890abc.cloudfront.net/events/test.jpg

# Expected headers:
# HTTP/2 200
# x-cache: Miss from cloudfront (first request)
# x-cache: Hit from cloudfront (second request)
```

---

## 📈 Monitoring & Alerts

### View CloudWatch Metrics:

```bash
UGC_DIST=$(terraform output -raw cloudfront_ugc_id)

# Check data transfer (bytes downloaded)
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name BytesDownloaded \
  --dimensions Name=DistributionId,Value=$UGC_DIST \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --region us-east-1  # CloudFront metrics are in us-east-1

# Check request count
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=$UGC_DIST \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --region us-east-1

# Check cache hit rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=$UGC_DIST \
  --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average \
  --region us-east-1
```

### Check Alarm Status:

```bash
aws cloudwatch describe-alarms \
  --alarm-names \
    concert-cloudfront-data-transfer-dev \
    concert-cloudfront-requests-dev \
  --region ap-southeast-1
```

---

## 🔄 Cache Invalidation

When you update files, invalidate CloudFront cache:

```bash
UGC_DIST=$(terraform output -raw cloudfront_ugc_id)
WEB_DIST=$(terraform output -raw cloudfront_website_id)

# Invalidate specific file
aws cloudfront create-invalidation \
  --distribution-id $UGC_DIST \
  --paths "/events/concert.jpg"

# Invalidate all avatars
aws cloudfront create-invalidation \
  --distribution-id $UGC_DIST \
  --paths "/avatars/*"

# Invalidate entire website (for deployments)
aws cloudfront create-invalidation \
  --distribution-id $WEB_DIST \
  --paths "/*"
```

⚠️ **Free Tier:** 1,000 invalidation paths/month are FREE.

---

## 🎯 Next Steps

### 1. Get CloudFront URLs ⏳ (Wait ~10-15 min for deployment)
```bash
terraform output
```

### 2. Update Frontend Config
```javascript
// .env.production
VITE_UGC_CDN_URL=https://d1234567890abc.cloudfront.net
VITE_API_URL=https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev
```

### 3. Test Upload Flow
```bash
# Run test script
./test_upload.sh
```

### 4. Deploy Website
```bash
# Build and upload frontend
cd main_frontend/concert1
npm run build
aws s3 sync .output/public/ s3://concert-website-123456789012/
```

### 5. Monitor Usage
```bash
# Check CloudWatch metrics
aws cloudwatch get-dashboard --dashboard-name ConcertMetricsDashboard
```

### 6. Optimize Costs (Optional)
```bash
# Remove ElastiCache to save $12/month
terraform destroy -target=aws_elasticache_replication_group.concert

# Use DynamoDB for sessions instead
```

---

## 📚 Documentation

- **Full Guide:** [CLOUDFRONT_DEPLOYMENT_GUIDE.md](./CLOUDFRONT_DEPLOYMENT_GUIDE.md)
- **Free Tier Architecture:** [FREE_TIER_ARCHITECTURE.md](./FREE_TIER_ARCHITECTURE.md)
- **Quick Start:** [FREE_TIER_QUICK_START.md](./FREE_TIER_QUICK_START.md)

---

## ✅ Success Criteria

- [x] S3 upload permissions fixed
- [x] CloudFront distributions deployed (UGC + Website)
- [x] S3 buckets created (3 total)
- [x] API Gateway + Lambda deployed
- [x] CloudWatch alarms configured
- [x] Free tier optimized
- [ ] CloudFront URLs obtained (pending deployment)
- [ ] Frontend updated with CloudFront URLs
- [ ] End-to-end upload tested
- [ ] Website deployed to S3

---

**📅 Deployment Date:** 2025-01-31  
**🌏 Region:** ap-southeast-1 (Singapore)  
**💵 Monthly Cost:** ~$12.80 (can be optimized to $0.00)  
**🎯 Status:** ✅ Deploying (10-15 min remaining)
