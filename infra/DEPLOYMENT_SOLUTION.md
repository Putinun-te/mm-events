# AWS Account Limitations Summary

## Current Situation

Your AWS account has several limitations that prevent standard deployment options:

### ❌ Blocked Services
1. **Application Load Balancer (ALB)** - Cannot create (account restriction)
2. **AWS App Runner** - Subscription required
3. **Lambda** - Works but has 60-120s cold starts (unusable for web API)

### ✅ Working Infrastructure
- **EC2**: t3.small running (but in wrong VPC)
- **RDS MySQL**: In serverless VPC (vpc-0a5017f4d8e1962ee)
- **ElastiCache Redis**: In serverless VPC
- **S3, Cognito, EFS**: All working

### 🔴 Critical Issue
Your existing EC2 instance (i-031914475e91af608, IP: 3.234.205.4) is in **VPC vpc-077128945cf424869**  
But all new infrastructure is in **VPC vpc-0a5017f4d8e1962ee**

**Result**: EC2 cannot reach RDS/Redis → Application fails to start

---

## Solutions

### Option 1: Launch New EC2 in Serverless VPC (Recommended)

**Cost**: ~$15/month (t3.small)  
**Time**: 10 minutes  
**Pros**: Clean, simple, everything in one VPC  
**Cons**: Need to launch new instance

**Steps**:
```bash
# 1. Get private subnet from serverless VPC
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-0a5017f4d8e1962ee" "Name=tag:Type,Values=Private" \
  --region us-east-1 \
  --query 'Subnets[0].SubnetId' \
  --output text)

# 2. Get Lambda security group (already has RDS/Redis access)
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-0a5017f4d8e1962ee" "Name=group-name,Values=concert-prod-lambda" \
  --region us-east-1 \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# 3. Launch EC2 in the correct VPC
aws ec2 run-instances \
  --image-id ami-0453ec754f44f9a4a \
  --instance-type t3.small \
  --key-name concert-key \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-api-server}]' \
  --iam-instance-profile Name=ecsInstanceRole \
  --region us-east-1

# 4. Wait for instance to start (2-3 minutes)
# 5. Get new instance ID and public IP
# 6. SSH and deploy Docker container (same as before)
```

### Option 2: Use Lambda with Provisioned Concurrency

**Cost**: ~$50/month  
**Time**: 5 minutes  
**Pros**: No new EC2, uses existing infrastructure  
**Cons**: More expensive, still some latency

**Steps**:
```bash
# Configure provisioned concurrency to keep Lambda warm
aws lambda put-provisioned-concurrency-config \
  --function-name concert-prod-api \
  --provisioned-concurrent-executions 1 \
  --qualifier '$LATEST' \
  --region us-east-1

# This keeps 1 Lambda instance always warm
# Cost: ~$13/month for 1 instance + regular Lambda costs
```

### Option 3: VPC Peering (Complex)

**Cost**: Free (data transfer costs only)  
**Time**: 30 minutes  
**Pros**: Keeps existing EC2  
**Cons**: Complex networking, route table updates needed

**Not recommended** - easier to launch new EC2

---

## Recommended Action Plan

### Immediate (Today - 15 minutes):

**Deploy new EC2 in serverless VPC**

```bash
#!/bin/bash
# Quick EC2 deployment script

# Get subnet and security group
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-0a5017f4d8e1962ee" "Name=tag:Type,Values=Private" \
  --region us-east-1 \
  --query 'Subnets[0].SubnetId' \
  --output text)

LAMBDA_SG=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-0a5017f4d8e1962ee" "Name=group-name,Values=concert-prod-lambda" \
  --region us-east-1 \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-0453ec754f44f9a4a \
  --instance-type t3.small \
  --key-name concert-key \
  --security-group-ids $LAMBDA_SG \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=concert-api-server}]' \
  --user-data '#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user' \
  --region us-east-1 \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance launching: $INSTANCE_ID"
echo "Waiting for instance to start..."

# Wait for instance
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region us-east-1

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "✅ Instance ready!"
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo ""
echo "Now run:"
echo "  # Update deploy script with new instance ID"
echo "  sed -i '' 's/i-031914475e91af608/$INSTANCE_ID/g' /Users/putinan/development/DevOps/develop/infra/deploy-ec2-automated.sh"
echo "  # Deploy application"
echo "  ./infra/deploy-ec2-automated.sh"
```

---

## Cost Comparison

| Option | Monthly Cost | Setup Time | Recommended |
|--------|--------------|------------|-------------|
| **New EC2 in VPC** | $15 | 15 min | ✅ **Yes** |
| Lambda + Provisioned | $50 | 5 min | ⚠️ OK |
| VPC Peering | $15 | 30 min | ❌ No |
| Request ALB access | $78 | 1-2 days | ⏱️ Long-term |

---

## What We Tried

1. ✅ ECS Fargate → ❌ Blocked (ALB restriction)
2. ✅ App Runner → ❌ Blocked (subscription required)
3. ✅ Lambda warming → ❌ Still times out (init timeout)
4. ✅ EC2 deployment → ❌ Different VPC (networking issue)

---

## Next Steps

**Run this command** to launch new EC2 in correct VPC:

```bash
cd /Users/putinan/development/DevOps/develop && \
./infra/launch-ec2-in-vpc.sh
```

Then the API will work at: `http://<NEW_EC2_IP>:8080`

---

## Alternative: Keep Lambda Warm for Now

If you don't want to launch new EC2, you can make Lambda somewhat usable:

```bash
# Add provisioned concurrency
aws lambda put-provisioned-concurrency-config \
  --function-name concert-prod-api \
  --provisioned-concurrent-executions 1 \
  --qualifier '$LATEST' \
  --region us-east-1

# This keeps 1 instance always warm
# First requests will be fast (~500ms instead of 60s)
# Cost: ~$50/month total
```

**Test after 5 minutes**:
```bash
curl https://cm6rrljxwi.execute-api.us-east-1.amazonaws.com/prod/health
# Should respond in <1 second
```

---

## Summary

**Problem**: AWS account limitations + VPC mismatch  
**Best Solution**: Launch new EC2 in serverless VPC ($15/month)  
**Quick Alternative**: Lambda provisioned concurrency ($50/month)  
**Long-term**: Request ALB access from AWS Support (1-2 days)

**Status**: Infrastructure ready, just need EC2 in correct network
