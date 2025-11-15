# Cost Optimization Summary

## ✅ Completed Optimizations

### 1. Released 3 Unused Elastic IPs (us-east-1)
**Savings: ~$10.80/month**
- 52.7.60.65 (eipalloc-0290a506a2b87a4d6) - DELETED
- 54.161.249.248 (eipalloc-088969fa79557bf74) - DELETED  
- 54.174.101.191 (eipalloc-0b064271842865aea) - DELETED

### 2. Disabled 2 Unused CloudFront Distributions
**Savings: ~$2-4/month**
- REDACTED_RESOURCE_ID (Backend EC2 direct) - DISABLED
- E1AOTTQDI43845 (Images S3) - DISABLED
- Can be deleted after 15 minutes

### 3. Removed Unused IAM Policies
**Savings: $0 (security improvement)**
- Removed Lambda & API Gateway policies from developer/deployment groups

---

## 📊 Current Active Resources

### ap-southeast-1 (Singapore) - PRODUCTION
- ✅ EC2: t4g.micro (concert-backend-graviton) - **NEEDED**
- ✅ RDS: db.t4g.micro (concert-prod-db) - **NEEDED**
- ✅ ALB: concert-backend-alb - **NEEDED**
- ✅ S3: 3 buckets (web, images, avatars) - **NEEDED**
- ✅ CloudFront: 2 distributions (frontend, backend) - **NEEDED**

### us-east-1 (Virginia) - UNUSED
- ⚠️ VPC: vpc-077128945cf424869 (concert-vpc) - Empty, has dependencies
- ⚠️ VPC: vpc-0a5017f4d8e1962ee (concert-prod-vpc) - Has 4 subnets
- ✅ Default VPC - Keep (free)

---

## 💰 Total Monthly Savings: ~$13-15/month

## ⚠️ VPCs in us-east-1
VPCs themselves are FREE, but they may have:
- Subnets (free)
- Route tables (free)
- Security groups (free)

**No cost impact from VPCs** - can leave them or delete if not needed.

---

## 🎯 Additional Cost Saving Options (Optional)

### Stop resources when not in use:
```bash
# Stop RDS (saves ~$12/month when stopped)
aws rds stop-db-instance --db-instance-identifier concert-prod-db --region ap-southeast-1

# Stop EC2 (saves ~$6/month when stopped)  
aws ec2 stop-instances --instance-ids i-0c3a8f2535e67df0c --region ap-southeast-1
```

### Start resources when needed:
```bash
# Start RDS
aws rds start-db-instance --db-instance-identifier concert-prod-db --region ap-southeast-1

# Start EC2
aws ec2 start-instances --instance-ids i-0c3a8f2535e67df0c --region ap-southeast-1
```

**Note:** RDS auto-starts after 7 days of being stopped.
