# 🚀 FREE TIER QUICK START GUIDE
## Get your Concert Platform running on AWS for $0/month!

---

## 🎯 **3-Minute Overview**

Your infrastructure is **95% FREE TIER READY**! Only 2 small changes needed:

### Current Status:
| Component | Status | Monthly Cost |
|-----------|--------|--------------|
| ✅ S3 Buckets (2) | Deployed | **$0** (5 GB free) |
| ✅ Lambda Function | Deployed | **$0** (1M free) |
| ✅ API Gateway HTTP | Deployed | **$0** (1M free) |
| ✅ DynamoDB Tables | Deployed | **$0** (25 GB free) |
| ⚠️ RDS MySQL | Deployed (Multi-AZ?) | **$0** (if single-AZ) |
| ❌ CloudFront CDN | NOT deployed | **$0** (1 TB free) |
| ❌ ElastiCache Redis | Deployed | **~$12** ⚠️ NOT FREE |

### **Action Required:**
1. **Add CloudFront** → Saves S3 costs, adds 1 TB free bandwidth
2. **Remove ElastiCache** → Replace with DynamoDB (saves $12/month)

---

## ⚡ **Quick Deploy CloudFront (5 minutes)**

```bash
cd /Users/putinan/development/DevOps/develop/aws

# 1. Verify cloudfront.tf exists
ls -la cloudfront.tf

# 2. Plan CloudFront deployment
terraform plan \
  -target=aws_cloudfront_distribution.s3_distribution \
  -target=aws_cloudfront_origin_access_identity.s3_oai \
  -out=tfplan_cloudfront

# 3. Apply (creates CloudFront distribution)
terraform apply tfplan_cloudfront

# 4. Get your CloudFront URL
terraform output cloudfront_url
# Example output: https://d1234567890abc.cloudfront.net
```

### **Update Frontend:**
Replace S3 URLs with CloudFront URL in your Nuxt app:

```javascript
// Before:
const imageUrl = 'https://concert-event-pictures-123456.s3.ap-southeast-1.amazonaws.com/event1.jpg'

// After:
const imageUrl = 'https://d1234567890abc.cloudfront.net/events/event1.jpg'
```

---

## 💰 **Remove ElastiCache (Save $12/month)**

### **Option 1: Automated Script**
```bash
cd /Users/putinan/development/DevOps/develop/aws
./optimize_free_tier.sh
# Follow prompts to:
# - Create DynamoDB session table
# - Remove ElastiCache
# - Set up billing alerts
```

### **Option 2: Manual Steps**

#### Step 1: Create DynamoDB Session Table
```bash
aws dynamodb create-table \
  --table-name concert-sessions-dev \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

#### Step 2: Update Backend (Spring Boot)
Add to `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-dynamodb</artifactId>
</dependency>
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>dynamodb</artifactId>
</dependency>
```

Add to `application.yml`:
```yaml
spring:
  session:
    store-type: dynamodb
    dynamodb:
      table-name: concert-sessions-dev

cloud:
  aws:
    region:
      static: ap-southeast-1
```

#### Step 3: Remove ElastiCache
```bash
# Delete the cluster
aws elasticache delete-replication-group \
  --replication-group-id concert-redis-dev \
  --region ap-southeast-1

# Remove from Terraform (comment out or delete elasticache.tf)
# Then run:
terraform plan
terraform apply
```

**Savings: $12/month → $0/month** ✅

---

## 📊 **Complete Architecture (100% Free Tier)**

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENT (Browser/Mobile)                     │
└───────────┬─────────────────────────────────┬───────────────────┘
            │                                 │
            │ HTTPS                           │ REST API
            ↓                                 ↓
┌───────────────────────┐        ┌──────────────────────────────┐
│   CLOUDFRONT CDN      │        │   EC2 t3.micro (FREE)        │
│   (1 TB/month FREE)   │        │   Spring Boot Backend        │
│   ├─ Event Pictures   │        │   - JWT Auth                 │
│   └─ User Avatars     │        │   - REST Controllers         │
└──────────┬────────────┘        └──────────┬───────────────────┘
           │                                │
           │ Origin                         │
           ↓                                ↓
┌───────────────────────┐        ┌──────────────────────────────┐
│   S3 BUCKETS (FREE)   │        │   RDS MySQL (FREE)           │
│   - 5 GB storage      │        │   db.t3.micro, single-AZ     │
│   - Encrypted         │        │   20 GB storage              │
│   - Versioning        │        └──────────────────────────────┘
└───────────────────────┘                   │
                                            │ Sessions
                                            ↓
                              ┌──────────────────────────────┐
                              │   DynamoDB (FREE)            │
                              │   - Sessions storage         │
                              │   - 25 GB, 25 WCU/RCU       │
                              └──────────────────────────────┘
```

### **Upload Flow:**
```
1. User clicks "Upload Photo" 
   ↓
2. Frontend → API Gateway → Lambda (generate presigned URL)
   ↓
3. Frontend uploads directly to S3 (no backend load)
   ↓
4. CloudFront serves images globally (cached, fast)
```

**All components: 100% FREE TIER** ✅

---

## 🎯 **Free Tier Limits - Don't Exceed These!**

| Service | Free Limit | How to Monitor |
|---------|------------|----------------|
| **S3 Storage** | 5 GB | `aws s3 ls --summarize` |
| **S3 GET Requests** | 20,000/month | CloudWatch (use CloudFront to reduce!) |
| **S3 PUT Requests** | 2,000/month | ~67 uploads/day |
| **CloudFront Data OUT** | 1 TB/month | ~33 GB/day (very generous) |
| **CloudFront Requests** | 10M/month | ~333k/day |
| **Lambda Invocations** | 1M/month | ~33k/day |
| **Lambda GB-seconds** | 400,000/month | Use 128 MB memory |
| **API Gateway** | 1M requests/month | HTTP API is FREE! |
| **RDS Hours** | 750 hrs/month | Run only 1 db.t3.micro |
| **RDS Storage** | 20 GB | Monitor with CloudWatch |
| **DynamoDB Storage** | 25 GB | Always free forever |
| **DynamoDB WCU/RCU** | 25 each | ~1M requests/month |
| **EC2** | 750 hrs/month | Run only 1 t3.micro |

### **Pro Tips to Stay Free:**
1. ✅ **Always use CloudFront** for S3 content (reduces GET requests)
2. ✅ **Compress images** before upload (stay under 5 GB)
3. ✅ **Use DynamoDB** for sessions, not ElastiCache
4. ✅ **Use HTTP API Gateway**, not REST API
5. ✅ **Set billing alarms** at $1, $5, $10
6. ✅ **Review AWS Cost Explorer** weekly

---

## 🚨 **Set Up Billing Alerts (DO THIS FIRST!)**

```bash
# 1. Create SNS topic for alerts
aws sns create-topic --name billing-alerts --region us-east-1

# 2. Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:YOUR_ACCOUNT:billing-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region us-east-1

# 3. Create alarm at $5
aws cloudwatch put-metric-alarm \
  --alarm-name BillingAlert-5USD \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 5.0 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:YOUR_ACCOUNT:billing-alerts \
  --region us-east-1
```

**You'll get email if charges exceed $5** ✅

---

## 📱 **Frontend Configuration**

### **Environment Variables (.env)**
```bash
# CloudFront CDN URLs
NUXT_PUBLIC_CDN_URL=https://d1234567890abc.cloudfront.net
NUXT_PUBLIC_EVENT_PICTURES_URL=https://d1234567890abc.cloudfront.net/events/
NUXT_PUBLIC_AVATARS_URL=https://d1234567890abc.cloudfront.net/avatars/

# API Gateway
NUXT_PUBLIC_API_GATEWAY_URL=https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev

# Backend (when deployed to EC2)
NUXT_PUBLIC_BACKEND_URL=http://your-ec2-ip:8080
```

### **Upload Component Example**
```vue
<script setup>
const uploadAvatar = async (file) => {
  // 1. Get presigned URL from API Gateway
  const response = await $fetch(`${config.public.apiGatewayUrl}/upload/avatar`, {
    method: 'POST',
    body: { 
      filename: file.name,
      contentType: file.type 
    }
  })
  
  // 2. Upload directly to S3 using presigned URL
  await $fetch(response.url, {
    method: 'PUT',
    body: file,
    headers: { 'Content-Type': file.type }
  })
  
  // 3. Image available immediately via CloudFront
  const imageUrl = `${config.public.avatarsUrl}${file.name}`
}
</script>
```

---

## 🖥️ **Backend Deployment to EC2 (Optional - Also FREE)**

### **Launch EC2 Instance**
```bash
# 1. Create key pair
aws ec2 create-key-pair \
  --key-name concert-key \
  --region ap-southeast-1 \
  --query 'KeyMaterial' \
  --output text > concert-key.pem
chmod 400 concert-key.pem

# 2. Launch t3.micro instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \  # Amazon Linux 2023
  --instance-type t3.micro \
  --key-name concert-key \
  --security-group-ids sg-YOUR_SG_ID \
  --subnet-id subnet-YOUR_SUBNET_ID \
  --region ap-southeast-1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-backend}]'
```

### **Deploy Spring Boot App**
```bash
# SSH to EC2
ssh -i concert-key.pem ec2-user@YOUR_EC2_IP

# Install Java 21
sudo yum install -y java-21-amazon-corretto

# Copy JAR file
scp -i concert-key.pem target/concert-backend.jar ec2-user@YOUR_EC2_IP:~/

# Run backend
java -jar concert-backend.jar \
  --spring.datasource.url=jdbc:mysql://YOUR_RDS_ENDPOINT:3306/concert_db \
  --spring.datasource.username=admin \
  --spring.datasource.password=YOUR_PASSWORD
```

**EC2 t3.micro: 750 hours/month = 100% FREE** ✅

---

## ✅ **Deployment Checklist**

### **Infrastructure (Terraform)**
- [ ] CloudFront distribution deployed
- [ ] S3 buckets created with encryption
- [ ] Lambda function deployed
- [ ] API Gateway HTTP API created
- [ ] RDS MySQL (db.t3.micro, **single-AZ only**)
- [ ] DynamoDB tables created
- [ ] ElastiCache **REMOVED** (or never deploy)
- [ ] Billing alarms set up

### **Application**
- [ ] Frontend uses CloudFront URLs
- [ ] Backend configured for DynamoDB sessions
- [ ] Environment variables set
- [ ] Image upload flow tested
- [ ] Images served via CloudFront

### **Monitoring**
- [ ] CloudWatch billing alarms active
- [ ] S3 storage monitored
- [ ] Lambda invocations tracked
- [ ] Weekly cost review scheduled

---

## 🎓 **Learning Resources**

- **AWS Free Tier:** https://aws.amazon.com/free/
- **CloudFront Guide:** https://docs.aws.amazon.com/cloudfront/
- **S3 Best Practices:** https://docs.aws.amazon.com/s3/
- **DynamoDB Session Storage:** https://docs.spring.io/spring-session/docs/current/reference/html5/#httpsession-dynamodb
- **API Gateway HTTP API:** https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html

---

## 💡 **Cost Optimization Tips**

### **Stay Under 5 GB S3 Storage:**
- Resize images to max 800KB before upload
- Delete old/unused event pictures after 6 months
- Use S3 Lifecycle rules to move to Glacier after 90 days

### **Reduce Lambda Invocations:**
- Cache presigned URLs in frontend (valid for 1 hour)
- Batch multiple file requests into one Lambda call
- Use CloudFront caching to reduce S3 GETs

### **Monitor Weekly:**
```bash
# Check current month's costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --region us-east-1
```

---

## 🎉 **You're All Set!**

Your Concert Platform is now running on AWS **100% FREE TIER**:
- ✅ Global CDN with CloudFront (1 TB/month free)
- ✅ Secure file storage with S3 (5 GB free)
- ✅ Serverless uploads with Lambda (1M free)
- ✅ Fast API with API Gateway HTTP (1M free)
- ✅ Reliable database with RDS MySQL (750 hrs free)
- ✅ Session storage with DynamoDB (25 GB always free)

**Total Monthly Cost: $0.00** 🎊

---

**Questions?** Check `FREE_TIER_ARCHITECTURE.md` for detailed architecture documentation.

**Last Updated:** October 31, 2025
