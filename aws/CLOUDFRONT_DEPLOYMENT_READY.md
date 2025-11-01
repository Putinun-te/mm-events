# 🚀 CloudFront Web Hosting - Ready to Deploy!

## ✅ What's Been Created

### 1. Infrastructure Configuration (Terraform)
- **cloudfront.tf** (630+ lines)
  - CloudFront distribution for web hosting
  - Origin Access Control (OAC) for secure S3 access
  - 3 S3 origins (frontend, events, avatars)
  - Custom cache policies (static vs dynamic content)
  - SPA routing function (404 → index.html)
  - 4 CloudWatch monitoring alarms
  
- **s3.tf** (enhanced)
  - Frontend S3 bucket with website hosting
  - CORS configuration for all buckets
  - Versioning enabled (rollback support)
  - Public access blocked (CloudFront only)

### 2. Deployment Tools
- **deploy-frontend-to-s3.sh** - Automated frontend deployment
  - Builds Nuxt application
  - Uploads to S3 with optimized cache headers
  - Creates CloudFront invalidation
  - Shows deployment URLs

- **upload-to-s3.sh** - Single file upload helper
- **batch-upload-to-s3.sh** - Batch upload for multiple files

### 3. Documentation
- **CLOUDFRONT_WEB_HOSTING_GUIDE.md** - Complete setup guide
  - Architecture overview
  - Deployment workflows
  - URL structure
  - Cost optimization tips
  - Troubleshooting guide

## 📊 Terraform Plan Summary

```
Plan: 58 to add, 0 to change, 0 to destroy
```

**What will be created:**

### CloudFront Resources (8 resources)
1. ✅ CloudFront distribution
2. ✅ Origin Access Control (OAC)
3. ✅ Cache policy for static assets
4. ✅ Cache policy for dynamic content
5. ✅ CloudFront function (SPA router)
6. ✅ 4 CloudWatch alarms (data transfer, requests, 4xx, 5xx errors)

### S3 Resources (12 resources)
1. ✅ Frontend bucket (concert-dev-frontend-*)
2. ✅ Frontend versioning
3. ✅ Frontend public access block
4. ✅ Frontend website configuration
5. ✅ Frontend CORS configuration
6. ✅ Frontend bucket policy (CloudFront OAC)
7. ✅ Event pictures CORS
8. ✅ Event pictures bucket policy
9. ✅ User avatars CORS
10. ✅ User avatars bucket policy
11-12. ✅ S3 outputs

### IAM Resources (39 resources)
- ✅ 4 IAM groups (developers, testers, deployment, admins)
- ✅ 33 IAM group policies
- ✅ Enhanced EC2 role permissions

### Existing Resources (No Changes)
- ✅ VPC and networking
- ✅ EC2 Auto Scaling Group
- ✅ RDS MySQL database
- ✅ ElastiCache Redis
- ✅ Cognito user pool
- ✅ CloudWatch logs

## 🎯 What You Get After Deployment

### Frontend Web Application
```
https://<distribution-id>.cloudfront.net/
```
- ✅ Global CDN (low latency worldwide)
- ✅ Free SSL/TLS certificate
- ✅ HTTP → HTTPS redirect
- ✅ SPA routing support (no 404 errors)
- ✅ Compression (Gzip + Brotli)

### Image URLs
```
https://<distribution-id>.cloudfront.net/events/<filename>
https://<distribution-id>.cloudfront.net/avatars/<filename>
```
- ✅ Cached for 1 year (fast loading)
- ✅ Served from edge locations
- ✅ Secure (HTTPS only)

### Cost Estimates

**Free Tier (First 12 Months):**
- 1 TB/month data transfer OUT ✅ FREE
- 10M HTTP/HTTPS requests/month ✅ FREE
- 5 GB S3 storage ✅ FREE

**After Free Tier:**
- ~$9/month for typical small app
  - 100 GB data transfer
  - 1M requests
  - 2 GB storage

## 📋 Deployment Steps

### Step 1: Deploy Infrastructure (10-15 minutes)

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Review plan
terraform plan

# Deploy
terraform apply
```

**Expected output:**
```
Apply complete! Resources: 58 added, 0 changed, 0 destroyed.

Outputs:

cloudfront_url = "https://d1234567890abc.cloudfront.net"
cloudfront_distribution_id = "E1234567890ABC"
frontend_bucket_name = "concert-dev-frontend-d453b7db"
...
```

### Step 2: Deploy Frontend Application (5 minutes)

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Build + Upload + Invalidate
./deploy-frontend-to-s3.sh
```

**Expected output:**
```
✓ Found frontend directory
✓ Dependencies already installed
✓ Build completed successfully
✓ Files uploaded to S3
✓ Found CloudFront distribution: E1234567890ABC
✓ Invalidation created: I1234567890ABC

========================================
Deployment Completed Successfully!
========================================

CloudFront URL:
  https://d1234567890abc.cloudfront.net
```

### Step 3: Test Application (After 5-15 min)

Wait for CloudFront cache invalidation, then:

```bash
# Get CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)

# Test web application
curl -I $CLOUDFRONT_URL

# Open in browser
open $CLOUDFRONT_URL
```

## 🔍 Verification Checklist

After deployment, verify:

- [ ] Terraform apply completed successfully
- [ ] CloudFront distribution shows "Deployed" status in AWS Console
- [ ] Frontend accessible at CloudFront URL
- [ ] All routes work (no 404 errors on SPA routes)
- [ ] HTTPS is enforced (HTTP redirects to HTTPS)
- [ ] Images load from /events/* and /avatars/*
- [ ] CloudWatch alarms are active
- [ ] S3 buckets have files uploaded

## 📊 Monitoring & Metrics

### CloudWatch Alarms Created

1. **Data Transfer** (`concert-cloudfront-data-transfer`)
   - Threshold: 900 GB/day (90% of 1 TB free tier)
   - Action: Alert when threshold exceeded

2. **Request Count** (`concert-cloudfront-requests`)
   - Threshold: 300k requests/day
   - Action: Alert when threshold exceeded

3. **4xx Error Rate** (`concert-cloudfront-4xx-errors`)
   - Threshold: >5% error rate
   - Action: Alert on client errors

4. **5xx Error Rate** (`concert-cloudfront-5xx-errors`)
   - Threshold: >1% error rate
   - Action: Alert on server errors

### View Metrics in AWS Console

1. Go to **CloudFront** → **Distributions**
2. Click on your distribution
3. View **Monitoring** tab
4. Metrics available:
   - Requests per minute
   - Data transfer
   - Error rates (4xx, 5xx)
   - Cache hit ratio

## 🎨 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet Users                       │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              CloudFront CDN (Global Edge Locations)          │
│  - Free SSL/TLS certificate                                  │
│  - 1 TB/month data transfer (free tier)                      │
│  - 10M requests/month (free tier)                            │
│  - Cache hit ratio optimization                              │
└───┬──────────────┬──────────────┬──────────────┬────────────┘
    │              │              │              │
    │ /            │ /events/*    │ /avatars/*   │ /api/* (optional)
    ▼              ▼              ▼              ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐
│ Frontend│  │  Event  │  │  User   │  │   Backend API   │
│   S3    │  │Pictures │  │ Avatars │  │   (via ALB)     │
│ Bucket  │  │   S3    │  │   S3    │  │  EC2 instances  │
└─────────┘  └─────────┘  └─────────┘  └─────────────────┘
    │              │              │              │
    └──────────────┴──────────────┴──────────────┘
                         │
                         ▼
              Private (No direct access)
              All access via CloudFront OAC
```

## 🔐 Security Features

✅ **S3 Security:**
- All buckets block public access
- Access only via CloudFront OAC
- Bucket policies restrict to CloudFront ARN
- Versioning enabled for rollback

✅ **CloudFront Security:**
- HTTPS enforced (TLS 1.2+)
- Custom header verification
- Origin Access Control (OAC)
- No direct S3 access

✅ **IAM Security:**
- Least privilege policies
- Separate permissions per group
- Backend EC2 role for uploads only

## 🚨 Important Notes

### Cache Invalidation
- **Cost**: First 1,000 paths FREE/month
- **Time**: 5-15 minutes to propagate
- **Automatic**: deployment script handles this

### Browser Caching
- Static assets: 1 year cache
- HTML files: 5 minutes cache
- API responses: No cache (when enabled)

### SPA Routing
- All non-file paths → `/index.html`
- Vue Router / React Router supported
- No 404 errors on page refresh

## 📞 Next Steps

After successful deployment:

1. **Configure Frontend API Base URL**
   ```javascript
   // In frontend config
   const API_BASE_URL = 'https://<cloudfront-domain>/api'
   ```

2. **Upload Sample Images**
   ```bash
   ./upload-to-s3.sh sample-event.jpg events
   ./upload-to-s3.sh sample-avatar.png avatars
   ```

3. **Monitor Costs**
   - Check CloudWatch alarms daily
   - Monitor AWS Billing dashboard
   - Set up budget alerts

4. **Optional: Custom Domain**
   - Register domain
   - Request ACM certificate
   - Update CloudFront settings
   - Create Route 53 alias

## 📚 Documentation Files

1. **CLOUDFRONT_WEB_HOSTING_GUIDE.md** - Complete guide
2. **This file** - Deployment summary
3. **cloudfront.tf** - Infrastructure code
4. **deploy-frontend-to-s3.sh** - Deployment script

## ✅ Ready to Deploy!

Everything is configured and ready. Just run:

```bash
cd /Users/putinan/development/DevOps/develop/aws
terraform apply
./deploy-frontend-to-s3.sh
```

Your web application will be live on CloudFront in ~20 minutes! 🎉
