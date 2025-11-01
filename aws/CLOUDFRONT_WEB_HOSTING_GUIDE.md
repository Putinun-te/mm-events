# CloudFront Web Hosting Setup Guide

Complete guide for hosting your web application on S3 with CloudFront CDN.

## 🎯 Overview

Your infrastructure now includes:
- **S3 Buckets**: Frontend hosting + Image storage (events, avatars)
- **CloudFront CDN**: Global content delivery with HTTPS
- **Automated Deployment**: Scripts for easy deployment

## 📦 Architecture

```
Internet Users
     ↓
CloudFront Distribution (Global CDN)
     ├─→ /            → S3 Frontend Bucket (index.html, app files)
     ├─→ /events/*    → S3 Event Pictures Bucket
     ├─→ /avatars/*   → S3 User Avatars Bucket
     └─→ /api/* (optional) → Backend API (via ALB)
```

## 🚀 Quick Start

### 1. Deploy CloudFront Infrastructure

```bash
cd aws

# Review changes
terraform plan

# Deploy S3 buckets, CloudFront distribution, and monitoring
terraform apply
```

**What this creates:**
- Frontend S3 bucket with static website hosting
- CloudFront distribution with 4 monitoring alarms
- S3 bucket policies for CloudFront access
- Cache policies optimized for static/dynamic content
- SPA routing support (all routes → index.html)

### 2. Deploy Frontend Application

```bash
cd aws

# Build and deploy frontend to S3 + invalidate CloudFront cache
./deploy-frontend-to-s3.sh
```

**This script will:**
1. ✅ Install npm dependencies
2. ✅ Build Nuxt application (`npm run generate`)
3. ✅ Upload files to S3 with optimized cache headers
4. ✅ Create CloudFront invalidation (updates cache)
5. ✅ Display deployment URLs

### 3. Upload Images to S3

```bash
cd aws

# Upload single event image
./upload-to-s3.sh concert-poster.jpg events

# Upload batch of images
./batch-upload-to-s3.sh event-photos/ events may-2025

# Upload user avatar
./upload-to-s3.sh profile-pic.png avatars users/john123
```

## 📋 Infrastructure Details

### S3 Buckets

| Bucket | Purpose | CloudFront Path | Public Access |
|--------|---------|-----------------|---------------|
| `concert-dev-frontend-*` | Web application | `/` | No (via CloudFront only) |
| `concert-event-pictures-*` | Event images | `/events/*` | No (via CloudFront only) |
| `concert-user-avatars-*` | User avatars | `/avatars/*` | No (via CloudFront only) |

**Security:**
- ✅ All buckets block direct public access
- ✅ Accessible only via CloudFront (OAC authenticated)
- ✅ HTTPS enforced on all requests
- ✅ Versioning enabled for rollback capability

### CloudFront Configuration

**Cache Policies:**
- **Static Assets** (CSS, JS, images): 1 year max cache
- **HTML Files**: 5 minutes cache (for faster updates)
- **API Requests**: No cache (when enabled)

**Features:**
- ✅ **SPA Routing**: 404 → index.html (for client-side routing)
- ✅ **Compression**: Gzip + Brotli enabled
- ✅ **HTTPS**: TLS 1.2+ enforced
- ✅ **IPv6**: Enabled for modern devices
- ✅ **Edge Locations**: PriceClass_100 (North America + Europe)

**Monitoring:**
- 📊 Data transfer alarm (900 GB/day → 90% of 1 TB free tier)
- 📊 Request count alarm (300k/day → 90% of 10M/month)
- 📊 4xx error rate alarm (>5%)
- 📊 5xx error rate alarm (>1%)

### CloudFront Function (SPA Router)

Automatically handles client-side routing:
```javascript
// URIs without file extension → /index.html
/about       → /index.html
/events/123  → /index.html
/user/profile → /index.html

// Static files → direct path
/assets/logo.png → /assets/logo.png
/main.css        → /main.css
```

## 🔧 Deployment Workflows

### First-Time Deployment

```bash
# 1. Deploy infrastructure
cd aws
terraform apply

# 2. Get CloudFront URL
terraform output cloudfront_url
# Output: https://d1234567890abc.cloudfront.net

# 3. Deploy frontend
./deploy-frontend-to-s3.sh

# 4. Test application
# Visit the CloudFront URL (wait 5-15 min for invalidation)
```

### Update Frontend Code

```bash
# 1. Make changes to frontend code
cd ../main_frontend/concert1
# ... edit files ...

# 2. Deploy (builds + uploads + invalidates cache)
cd ../../aws
./deploy-frontend-to-s3.sh

# 3. Wait 5-15 minutes for CloudFront cache invalidation
# Then refresh your browser
```

### Upload New Images

```bash
cd aws

# Single file
./upload-to-s3.sh new-event-poster.jpg events

# Batch upload
./batch-upload-to-s3.sh concert-photos/ events june-2025

# Get CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)
echo "$CLOUDFRONT_URL/events/new-event-poster.jpg"
```

## 🌐 URL Structure

After deployment, your application URLs will be:

### CloudFront URLs (Production)
```bash
# Get your CloudFront domain
terraform output cloudfront_url
# Example: https://d1234567890abc.cloudfront.net

# Web Application
https://d1234567890abc.cloudfront.net/

# Event Images
https://d1234567890abc.cloudfront.net/events/poster-20250601.jpg

# User Avatars
https://d1234567890abc.cloudfront.net/avatars/user123.png

# API (when enabled)
https://d1234567890abc.cloudfront.net/api/auth/login
```

### Direct S3 URLs (Not Recommended - Blocked)
```bash
# These URLs are BLOCKED by bucket policy
# All access must go through CloudFront
https://concert-dev-frontend-*.s3.amazonaws.com/  ❌ BLOCKED
```

## 📊 Cost Optimization

### Free Tier Limits (First 12 Months)
- ✅ **CloudFront**: 1 TB data transfer OUT/month
- ✅ **CloudFront**: 10M HTTP/HTTPS requests/month
- ✅ **S3**: 5 GB storage
- ✅ **S3**: 20k GET requests, 2k PUT requests

### Cost After Free Tier
**Typical small app costs:**
- CloudFront: $0.085/GB (first 10 TB/month)
- S3 storage: $0.023/GB/month
- S3 GET requests: $0.0004 per 1k requests
- **Example**: 100 GB transfer + 1M requests = ~$9/month

### Tips to Stay in Free Tier
1. ✅ Use CloudFront caching (reduces S3 GET requests)
2. ✅ Set long cache TTLs for static assets (1 year)
3. ✅ Compress images before upload
4. ✅ Monitor CloudWatch alarms
5. ✅ Use PriceClass_100 (North America + Europe only)

## 🔐 Security Features

### Transport Security
- ✅ HTTPS enforced (redirect HTTP → HTTPS)
- ✅ TLS 1.2+ only
- ✅ Modern cipher suites

### Access Control
- ✅ S3 buckets private (no direct access)
- ✅ CloudFront OAC (Origin Access Control)
- ✅ Custom header verification (`X-Origin-Verify`)
- ✅ Backend IAM role for uploads only

### CORS Configuration
```javascript
// Configured for all buckets
{
  "AllowedOrigins": ["*"],
  "AllowedMethods": ["GET", "HEAD", "PUT", "POST"],
  "AllowedHeaders": ["*"],
  "ExposeHeaders": ["ETag"],
  "MaxAgeSeconds": 3000
}
```

## 🛠️ Advanced Configuration

### Enable Backend API Proxying

Uncomment in `cloudfront.tf`:

```hcl
# 1. Add backend origin (line ~140)
origin {
  domain_name = aws_lb.backend_alb.dns_name
  origin_id   = "backend-api"
  # ... config ...
}

# 2. Add API cache behavior (line ~200)
ordered_cache_behavior {
  path_pattern = "/api/*"
  target_origin_id = "backend-api"
  # ... config ...
}
```

Then apply:
```bash
terraform apply
```

### Custom Domain with SSL

1. **Register domain** (Route 53 or external)
2. **Request ACM certificate** (us-east-1 region):
   ```bash
   aws acm request-certificate \
     --domain-name yourdomain.com \
     --validation-method DNS \
     --region us-east-1
   ```
3. **Update CloudFront**:
   ```hcl
   viewer_certificate {
     acm_certificate_arn = "arn:aws:acm:us-east-1:..."
     ssl_support_method = "sni-only"
     minimum_protocol_version = "TLSv1.2_2021"
   }
   
   aliases = ["yourdomain.com", "www.yourdomain.com"]
   ```
4. **Create Route 53 alias** → CloudFront distribution

### Configure Geographic Restrictions

```hcl
restrictions {
  geo_restriction {
    restriction_type = "whitelist"
    locations = ["US", "CA", "GB", "DE", "TH", "SG", "JP"]
  }
}
```

## 📈 Monitoring & Debugging

### Check Deployment Status

```bash
# List S3 bucket contents
aws s3 ls s3://concert-dev-frontend-d453b7db/ --recursive

# Get CloudFront distribution info
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront get-distribution --id $DIST_ID

# Check invalidation status
aws cloudfront list-invalidations --distribution-id $DIST_ID
```

### CloudFront Metrics (AWS Console)

1. Go to **CloudFront** → **Distributions**
2. Select your distribution
3. View **Monitoring** tab:
   - Requests
   - Data transfer
   - Error rates (4xx, 5xx)
   - Cache hit ratio

### Common Issues

**Problem**: Changes not showing up
- **Solution**: Wait 5-15 min for invalidation OR clear browser cache

**Problem**: 403 Access Denied on images
- **Solution**: Check S3 bucket policy allows CloudFront OAC

**Problem**: API requests failing
- **Solution**: Uncomment backend origin in cloudfront.tf

**Problem**: High costs
- **Solution**: Check CloudWatch alarms, optimize cache TTLs

## 🔄 Rollback Procedures

### Rollback Frontend Deployment

S3 versioning is enabled, so you can restore previous versions:

```bash
# List versions of index.html
aws s3api list-object-versions \
  --bucket concert-dev-frontend-d453b7db \
  --prefix index.html

# Copy specific version
aws s3api copy-object \
  --bucket concert-dev-frontend-d453b7db \
  --copy-source concert-dev-frontend-d453b7db/index.html?versionId=VERSION_ID \
  --key index.html

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

### Rollback Infrastructure

```bash
# View Terraform state
terraform show

# Rollback to previous state
git log  # Find previous commit
git checkout <commit-hash> -- *.tf
terraform apply
```

## 📚 Reference Commands

```bash
# View all outputs
terraform output

# Get specific output
terraform output cloudfront_url
terraform output cloudfront_distribution_id
terraform output frontend_bucket_name

# Test CloudFront URL
curl -I $(terraform output -raw cloudfront_url)

# Upload test file
echo "Hello CloudFront" > test.html
aws s3 cp test.html s3://concert-dev-frontend-d453b7db/
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/test.html"

# View invalidation status
aws cloudfront list-invalidations \
  --distribution-id $(terraform output -raw cloudfront_distribution_id)
```

## ✅ Post-Deployment Checklist

- [ ] Terraform apply successful
- [ ] CloudFront distribution deployed
- [ ] Frontend deployed to S3
- [ ] CloudFront invalidation created
- [ ] Application accessible via CloudFront URL
- [ ] Images loading correctly
- [ ] SPA routing working (no 404s)
- [ ] HTTPS enforced
- [ ] CloudWatch alarms configured
- [ ] Cost monitoring enabled

## 🎉 Success Metrics

Your deployment is successful when:
- ✅ Frontend loads at CloudFront URL
- ✅ All routes work (no 404 errors)
- ✅ Images display from /events/* and /avatars/*
- ✅ HTTPS is enforced (HTTP redirects)
- ✅ CloudWatch shows no errors
- ✅ Cache hit ratio > 70% (after warm-up)

---

## Need Help?

**View logs:**
```bash
# CloudFront access logs (if enabled)
aws s3 ls s3://cloudfront-logs-bucket/cloudfront-logs/

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=$DIST_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

**Common AWS CLI commands:**
- `aws cloudfront help`
- `aws s3 help`
- `terraform output --help`
