# API Gateway ALB Restriction - Workaround Options

## Issue
AWS account is restricted from creating Application Load Balancers (ALB):
```
Error: operation error Elastic Load Balancing v2: CreateLoadBalancer
This AWS account currently does not support creating load balancers.
For more information, please contact AWS Support.
```

## Current Situation
- ✅ **Deployed**: 40+ API Gateway resources (REST API, endpoints, CORS, Cognito authorizer)
- ❌ **Blocked**: Application Load Balancer creation (similar to CloudFront restriction)
- ✅ **Working**: EC2 Auto Scaling Group already running with backend

## Options

### Option 1: Contact AWS Support (RECOMMENDED for Production)
Request approval to create Application Load Balancers:

1. **AWS Console** → **Support** → **Create Case**
2. **Case Type**: Service limit increase
3. **Service**: Elastic Load Balancing
4. **Request**:
   ```
   Subject: Request to Enable Application Load Balancer Creation
   
   Hello AWS Support,
   
   I am working on a production concert booking platform and need to create
   an Application Load Balancer to integrate API Gateway with my EC2 backend.
   
   Current setup:
   - AWS Account: 123456789012
   - Region: us-east-1
   - Use case: API Gateway VPC Link → ALB → EC2 Auto Scaling Group
   - Backend: Spring Boot application on EC2
   
   The error message states:
   "This AWS account currently does not support creating load balancers"
   
   Could you please enable ALB creation for my account?
   
   Thank you!
   ```

**Timeline**: Usually 1-2 business days

### Option 2: Direct EC2 Integration (TEMPORARY Workaround)
Modify API Gateway to connect directly to EC2 instances (no ALB):

**Pros**:
- No AWS Support approval needed
- Can deploy immediately
- Still uses Cognito authentication
- CORS still works

**Cons**:
- ⚠️ No load balancing across multiple EC2 instances
- ⚠️ No health checks
- ⚠️ Manual EC2 IP management if instance changes
- ⚠️ Less fault-tolerant

**Implementation**: Modify `api_gateway.tf` to use HTTP integration pointing directly to EC2 public IP

### Option 3: Use CloudFront + S3 Website for API (NOT RECOMMENDED)
Wait for CloudFront approval, then use CloudFront as API proxy

**Cons**:
- Still requires CloudFront approval (same issue)
- Not ideal for dynamic API endpoints
- Caching complexities

### Option 4: Frontend Direct EC2 Access (SIMPLEST but NOT SECURE)
Update frontend to call EC2 directly instead of API Gateway

**Pros**:
- No API Gateway complexity
- Works immediately

**Cons**:
- ❌ No Cognito integration at API level
- ❌ No rate limiting
- ❌ Security concerns (direct EC2 exposure)
- ❌ CORS configuration on backend required

## Recommendation

### For This Project:
1. **NOW**: Use **Option 4** (Frontend → EC2) temporarily
   - Update frontend to call: `http://ec2-public-ip:8080/api/*`
   - Configure backend CORS for frontend origin
   - Use Cognito JWT on frontend, validate on backend
   
2. **Submit AWS Support request** for both:
   - CloudFront distribution creation
   - Application Load Balancer creation

3. **When approved**: Switch to full architecture:
   ```
   Frontend (CloudFront + S3)
      ↓
   API Gateway (Cognito auth, rate limiting)
      ↓
   VPC Link → ALB → EC2 Auto Scaling
   ```

## Current Architecture (What We Can Deploy Now)

```
┌─────────────────────────────────────────┐
│  Users/Browsers                         │
└──────────────────┬──────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌───────────────┐    ┌─────────────────┐
│  S3 Static    │    │   EC2 Backend   │
│  Website      │    │   (Direct)      │
│  (Frontend)   │    │  :8080/api/*    │
└───────────────┘    └─────────────────┘
        │                     │
        └─────────┬───────────┘
                  │
                  ▼
         ┌────────────────┐
         │   RDS MySQL    │
         │   + Redis      │
         └────────────────┘
```

## Terraform State Cleanup

Since ALB creation failed mid-deployment, clean up:

```bash
cd aws/

# Destroy partially created API Gateway resources
terraform destroy \
  -target=aws_api_gateway_rest_api.concert_api \
  -target=aws_api_gateway_vpc_link.backend \
  -target=aws_lb_target_group.backend \
  -target=aws_autoscaling_attachment.backend \
  -target=aws_security_group.alb

# Or comment out api_gateway.tf and re-run
mv api_gateway.tf api_gateway.tf.disabled
terraform apply

# Re-enable when ALB is approved
mv api_gateway.tf.disabled api_gateway.tf
terraform init
terraform apply
```

## Next Steps

1. **Clean up failed deployment**:
   ```bash
   cd aws/
   mv api_gateway.tf api_gateway.tf.disabled
   terraform apply
   ```

2. **Get EC2 Public IP**:
   ```bash
   terraform output ec2_public_ip
   # Or from AWS Console
   ```

3. **Update frontend API base URL**:
   ```javascript
   // main_frontend/concert1/nuxt.config.ts
   export default defineNuxtConfig({
     runtimeConfig: {
       public: {
         apiBase: 'http://EC2-PUBLIC-IP:8080'
       }
     }
   })
   ```

4. **Configure backend CORS**:
   ```java
   // Allow S3 website origin
   @CrossOrigin(origins = "http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com")
   ```

5. **Submit AWS Support tickets** for CloudFront + ALB

6. **Test application**:
   - Frontend can access backend API
   - Cognito login works
   - Event creation works
   - Photo upload works (to S3)

## Cost Comparison

### Without API Gateway + ALB (Current):
- EC2 (t3.micro): ~$7.50/month
- RDS (db.t3.micro): ~$15/month
- S3: ~$1/month
- **Total: ~$23.50/month**

### With API Gateway + ALB (After Approval):
- Above + API Gateway: ~$3.50/month
- Above + ALB: ~$16/month
- **Total: ~$43/month**

## Support Template

Use this when contacting AWS Support:

```
Subject: Request to Enable Load Balancer and CloudFront Services

Hello AWS Support,

I need assistance enabling two AWS services for my concert booking platform:

1. **Application Load Balancer (ELB)**
   - Current error: "This AWS account currently does not support creating load balancers"
   - Region: us-east-1
   - Use case: Backend API load balancing for production workload

2. **CloudFront Distribution**
   - Current error: "Your account must be verified before you can add new CloudFront resources"
   - Region: Global
   - Use case: CDN for static website hosting

Account Details:
- AWS Account: 123456789012
- Region: us-east-1
- Project: Production concert booking platform
- Timeline: Needed for production launch

Both services are critical for my application architecture. Could you please
enable these services for my account?

Thank you for your assistance!
```

## Resources Created (Before ALB Failure)

Successfully created:
- ✅ API Gateway REST API (`tkczyf26f6`)
- ✅ 10 API resources/endpoints
- ✅ Cognito authorizer
- ✅ 24 CORS integration resources
- ✅ CloudWatch log group
- ✅ IAM role for S3 photo uploads
- ✅ Target group for EC2
- ✅ Auto Scaling attachment
- ✅ ALB security group
- ✅ EC2 security group rule (allow ALB traffic)

Not created (blocked):
- ❌ Application Load Balancer
- ❌ ALB Listener
- ❌ VPC Link
- ❌ API Gateway deployment
- ❌ API Gateway stage

## Files Reference

- `api_gateway.tf` - Full API Gateway configuration (685 lines)
- `API_GATEWAY_SETUP_GUIDE.md` - Complete deployment guide
- `API_GATEWAY_IMPLEMENTATION_SUMMARY.md` - Quick reference
- `CLOUDFRONT_ENABLE_WHEN_READY.md` - CloudFront enable instructions

---

**Status**: Waiting for AWS Support approval for ALB + CloudFront  
**Workaround**: Direct EC2 access from frontend (functional but not production-ready)  
**Timeline**: 1-2 business days for support response
