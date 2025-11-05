# Deploy Spring Boot API to EC2

## Quick Deployment (5 minutes)

Your AWS account has limitations on ALB and App Runner, but you have a **t3.small EC2** instance running that's perfect for hosting the Spring Boot API!

### Step 1: Get EC2 Connection Info

```bash
# Get your EC2 public IP
EC2_IP=$(aws ec2 describe-instances \
  --instance-ids i-031914475e91af608 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "EC2 IP: $EC2_IP"
```

### Step 2: SSH into EC2

```bash
# Find your SSH key
ssh -i ~/.ssh/your-key.pem ec2-user@$EC2_IP

# Or if using AWS Systems Manager Session Manager:
aws ssm start-session --target i-031914475e91af608 --region us-east-1
```

### Step 3: Install Docker (if not installed)

```bash
# On the EC2 instance:
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Log out and back in for group changes to take effect
exit
# SSH back in
```

### Step 4: Login to ECR and Pull Image

```bash
# On the EC2 instance:
aws ecr get-login-password --region us-east-1 | \
  sudo docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Pull the Spring Boot image
sudo docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2
```

### Step 5: Run the Container

```bash
# Stop any existing container
sudo docker stop concert-api 2>/dev/null || true
sudo docker rm concert-api 2>/dev/null || true

# Start the Spring Boot API
sudo docker run -d \
  --name concert-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert" \
  -e SPRING_DATASOURCE_USERNAME="concert" \
  -e SPRING_DATASOURCE_PASSWORD="REDACTED_SECRET" \
  -e SPRING_PROFILES_ACTIVE="prod" \
  -e SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
  -e REDIS_ENDPOINT="concert-prod-redis-tx4y2n.serverless.use1.cache.amazonaws.com" \
  -e REDIS_PORT="6379" \
  -e COGNITO_USER_POOL_ID="us-east-1_nTZpyinXc" \
  -e COGNITO_CLIENT_ID="5fpck32uhi8m87b5tkirvaf0iu" \
  -e S3_BUCKET_NAME="concert-prod-web-123456789012" \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2
```

### Step 6: Verify Deployment

```bash
# Watch logs as Spring Boot starts (takes 30-60 seconds)
sudo docker logs -f concert-api

# Once you see "Started ConcertBackendApplication", test it:
curl http://localhost:8080/health

# Should return: {"status":"UP"}
```

### Step 7: Open Security Group Port 8080

```bash
# From your local machine:
# Get the security group ID
SG_ID=$(aws ec2 describe-instances \
  --instance-ids i-031914475e91af608 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo "Security Group: $SG_ID"

# Add rule to allow port 8080 from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region us-east-1
```

### Step 8: Test from Your Machine

```bash
# Get EC2 public IP
EC2_IP=$(aws ec2 describe-instances \
  --instance-ids i-031914475e91af608 \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Test the API
curl http://$EC2_IP:8080/health
curl http://$EC2_IP:8080/api/auth/test

# Expected response:
# {"status":"UP"}
# {"message":"Public endpoint - no authentication required"}
```

---

## Alternative: CloudWatch Warming (Keep Lambda Warm)

I've already set up CloudWatch Events to keep your Lambda warm:

- ✅ Rule created: `keep-lambda-warm`
- ✅ Triggers every 5 minutes
- ✅ Prevents cold starts

**However**, Lambda still times out during initialization because Spring Boot needs 60+ seconds to start, which exceeds Lambda's init timeout.

### Fix Lambda Timeout (Optional)

The Lambda has environment variables configured but needs the init timeout increased:

```bash
# Lambda currently has 120s function timeout
# But init phase has only 10s timeout (cannot be changed)
# This is why it keeps timing out

# The only solution is to optimize the Spring Boot app for Lambda:
# 1. Use Spring Native (GraalVM) - reduces startup to <1 second
# 2. Use Spring Cloud Function - designed for serverless
# 3. OR use EC2 (recommended for traditional Spring Boot)
```

---

## Why EC2 is the Best Option

Given your account limitations:

| Service | Status | Monthly Cost |
|---------|--------|--------------|
| **EC2 (t3.small)** | ✅ Working | $15 | 
| Lambda + API Gateway | ⚠️ Cold start issues | $40 |
| ECS Fargate + ALB | ❌ ALB creation blocked | N/A |
| App Runner | ❌ Subscription required | N/A |

**Recommendation**: Deploy to EC2 (Steps 1-8 above)

---

## Monitoring & Maintenance

### View Container Logs
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@$EC2_IP
sudo docker logs concert-api --tail 100 -f
```

### Restart Container
```bash
sudo docker restart concert-api
```

### Update to New Version
```bash
# Pull latest image
aws ecr get-login-password --region us-east-1 | \
  sudo docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

sudo docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2

# Restart with new image
sudo docker stop concert-api
sudo docker rm concert-api
# Then run the docker run command from Step 5 again
```

### Check Container Health
```bash
sudo docker ps
sudo docker stats concert-api
```

---

## Summary

**Current Status**:
- ✅ Lambda infrastructure deployed but unusable (cold start timeout)
- ✅ CloudWatch warming configured (helps but doesn't solve init timeout)
- ✅ EC2 instance available (t3.small running)
- ✅ All supporting services ready (RDS, Redis, S3, Cognito, EFS)

**Next Action**:
Follow Steps 1-8 above to deploy to EC2 for immediate production-ready API.

**API Endpoint After Deployment**:
- `http://<EC2_IP>:8080/health`
- `http://<EC2_IP>:8080/api/auth/register`
- `http://<EC2_IP>:8080/api/auth/login`

**Cost**: ~$15/month (EC2 t3.small)
