# AWS Account Limitation: Load Balancer Creation Blocked

## Issue

Your AWS account currently **does not support creating load balancers**.

```
Error: creating ELBv2 application Load Balancer (concert-prod-alb): 
OperationNotPermitted: This AWS account currently does not support 
creating load balancers. For more information, please contact AWS Support.
```

## Why This Happens

This is a common restriction on:
1. **New AWS accounts** (< 30 days old)
2. **Accounts with unpaid bills**
3. **Accounts flagged for verification**
4. **Free tier accounts** (sometimes)

AWS restricts certain services to prevent fraud and abuse.

## Solution Options

### Option 1: Contact AWS Support (Recommended for Production)

**Steps**:
1. Go to: https://console.aws.amazon.com/support/home
2. Create a case → Service limit increase
3. Select: **Elastic Load Balancing** → **Application Load Balancers**
4. Request: "Enable ALB creation for account"
5. Business justification: "Need ALB for production Spring Boot API deployment"

**Timeline**: Usually 1-2 business days

### Option 2: Use API Gateway + Lambda (Current Setup)

You already have this deployed! It works, just has cold start issues.

**Current Endpoint**:
```
https://cm6rrljxwi.execute-api.us-east-1.amazonaws.com/prod
```

**Issue**: 60-120 second cold starts for Spring Boot

**Workaround**: Keep Lambda warm by pinging it every 5 minutes:
```bash
# Create a CloudWatch Event Rule
aws events put-rule \
  --name keep-lambda-warm \
  --schedule-expression "rate(5 minutes)" \
  --region us-east-1

# Add Lambda as target
aws events put-targets \
  --rule keep-lambda-warm \
  --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:123456789012:function:concert-prod-api" \
  --region us-east-1

# Grant CloudWatch Events permission
aws lambda add-permission \
  --function-name concert-prod-api \
  --statement-id AllowCloudWatchEventsInvoke \
  --action 'lambda:InvokeFunction' \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:us-east-1:123456789012:rule/keep-lambda-warm \
  --region us-east-1
```

**Cost**: ~$5/month for keeping Lambda warm 24/7

### Option 3: Deploy to Different Region

Some regions might allow ALB creation:

```bash
# Try us-west-2 (Oregon)
cd /Users/putinan/development/DevOps/develop/infra/terraform/ecs-fargate
sed -i '' 's/us-east-1/us-west-2/g' terraform.tfvars
terraform plan
```

**Note**: You'd need to recreate all infrastructure in the new region.

### Option 4: Use EC2 + Docker (No Load Balancer)

Deploy Spring Boot directly to EC2 without ALB:

**Cost**: ~$10-15/month (t3.micro or t3.small)

**Steps**:
1. Launch EC2 instance in public subnet
2. Install Docker
3. Run your container directly
4. Use EC2 public IP/DNS

**Limitation**: 
- No auto-scaling
- No high availability
- Manual management

### Option 5: Use AWS App Runner (ALB Alternative)

AWS App Runner is a simpler container service that doesn't require ALB:

**Pros**:
- Automatically deploys from ECR
- Built-in HTTPS
- Auto-scaling
- No ALB needed!

**Cost**: ~$25-40/month

**Quick Deploy**:
```bash
aws apprunner create-service \
  --service-name concert-api \
  --source-configuration '{
    "ImageRepository": {
      "ImageIdentifier": "123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "8080",
        "RuntimeEnvironmentVariables": {
          "SPRING_DATASOURCE_URL": "jdbc:mysql://concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert",
          "SPRING_DATASOURCE_USERNAME": "concert",
          "SPRING_PROFILES_ACTIVE": "prod",
          "SPRING_JPA_HIBERNATE_DDL_AUTO": "update"
        }
      }
    },
    "AutoDeploymentsEnabled": true,
    "AuthenticationConfiguration": {
      "AccessRoleArn": "arn:aws:iam::123456789012:role/AppRunnerECRAccessRole"
    }
  }' \
  --instance-configuration '{
    "Cpu": "1 vCPU",
    "Memory": "2 GB"
  }' \
  --health-check-configuration '{
    "Protocol": "HTTP",
    "Path": "/health",
    "Interval": 10,
    "Timeout": 5,
    "HealthyThreshold": 1,
    "UnhealthyThreshold": 5
  }' \
  --region us-east-1
```

## Comparison

| Option | Time to Deploy | Monthly Cost | No Cold Starts | Production Ready |
|--------|----------------|--------------|----------------|------------------|
| **1. Request ALB Access** | 1-2 days | $78 | ✅ | ✅ Best |
| **2. Keep Lambda Warm** | Today | $40 | ✅ | ⚠️ OK |
| **3. Different Region** | Today | $78 | ✅ | ✅ Good |
| **4. EC2 Direct** | Today | $15 | ✅ | ⚠️ No HA |
| **5. App Runner** | Today | $35 | ✅ | ✅ Good |

## Recommendation

### For Immediate Deployment (Today)
→ **Use AWS App Runner** (Option 5)
- No ALB needed
- Built-in HTTPS and auto-scaling  
- Cheaper than ECS Fargate ($35 vs $78)
- Production-ready

### For Best Long-Term Solution
→ **Request ALB access** (Option 1) then deploy ECS Fargate
- Industry standard
- Most flexible
- Best for future scaling

## Next Steps

### Quick Fix (Deploy Today with App Runner)

1. Create IAM role for App Runner to access ECR:
```bash
aws iam create-role \
  --role-name AppRunnerECRAccessRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "build.apprunner.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name AppRunnerECRAccessRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess
```

2. Get database password from Secrets Manager:
```bash
DB_PASS=$(aws secretsmanager get-secret-value \
  --secret-id concert-prod/database \
  --region us-east-1 \
  --query 'SecretString' \
  --output text | jq -r '.password')
```

3. Deploy to App Runner:
```bash
aws apprunner create-service \
  --service-name concert-api \
  --source-configuration file://apprunner-source.json \
  --instance-configuration '{
    "Cpu": "1 vCPU",
    "Memory": "2 GB"
  }' \
  --health-check-configuration '{
    "Protocol": "HTTP",
    "Path": "/health"
  }' \
  --region us-east-1
```

Where `apprunner-source.json`:
```json
{
  "ImageRepository": {
    "ImageIdentifier": "123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:lambda-v2",
    "ImageRepositoryType": "ECR",
    "ImageConfiguration": {
      "Port": "8080",
      "RuntimeEnvironmentVariables": {
        "SPRING_DATASOURCE_URL": "jdbc:mysql://concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert",
        "SPRING_DATASOURCE_USERNAME": "concert",
        "SPRING_DATASOURCE_PASSWORD": "REDACTED_SECRET",
        "SPRING_PROFILES_ACTIVE": "prod",
        "SPRING_JPA_HIBERNATE_DDL_AUTO": "update",
        "REDIS_ENDPOINT": "concert-prod-redis-tx4y2n.serverless.use1.cache.amazonaws.com",
        "REDIS_PORT": "6379",
        "COGNITO_USER_POOL_ID": "us-east-1_nTZpyinXc",
        "COGNITO_CLIENT_ID": "5fpck32uhi8m87b5tkirvaf0iu",
        "S3_BUCKET_NAME": "concert-prod-web-123456789012"
      }
    }
  },
  "AutoDeploymentsEnabled": true,
  "AuthenticationConfiguration": {
    "AccessRoleArn": "arn:aws:iam::123456789012:role/AppRunnerECRAccessRole"
  }
}
```

4. Get App Runner URL:
```bash
aws apprunner describe-service \
  --service-arn $(aws apprunner list-services --query 'ServiceSummaryList[0].ServiceArn' --output text) \
  --query 'Service.ServiceUrl' \
  --output text
```

## Current Status

- ✅ Infrastructure attempted: ECS Fargate
- ❌ Blocked by: AWS account restriction on ALB creation
- ✅ Alternative ready: App Runner deployment
- ✅ Fallback working: Lambda with cold starts

**Action Required**: Choose one of the 5 options above to proceed.
