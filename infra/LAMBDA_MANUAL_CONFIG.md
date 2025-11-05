# Lambda Manual Configuration Required

## Problem
Spring Boot in Lambda has severe cold start issues (60+ seconds) due to:
- Traditional Spring Boot initialization
- Hibernate/JPA entity scanning
- Database connection pooling (HikariCP)
- VPC ENI attachment delays
- EFS mount initialization

## Current Manual Configuration

The Lambda function `concert-prod-api` requires these environment variables to be set manually via AWS CLI (Terraform has `ignore_changes` on environment):

```bash
# Get DB credentials from Secrets Manager
DB_USER=$(aws secretsmanager get-secret-value --secret-id concert-prod/database --region us-east-1 --query SecretString --output text | jq -r '.username')
DB_PASS=$(aws secretsmanager get-secret-value --secret-id concert-prod/database --region us-east-1 --query SecretString --output text | jq -r '.password')

# Update Lambda environment
aws lambda update-function-configuration \
  --function-name concert-prod-api \
  --region us-east-1 \
  --timeout 120 \
  --environment "Variables={
    SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com:3306/concert,
    SPRING_DATASOURCE_USERNAME=${DB_USER},
    SPRING_DATASOURCE_PASSWORD=${DB_PASS},
    SPRING_JPA_HIBERNATE_DDL_AUTO=update,
    SPRING_PROFILES_ACTIVE=prod,
    REDIS_ENDPOINT=concert-prod-redis-tx4y2n.serverless.use1.cache.amazonaws.com,
    REDIS_PORT=6379,
    COGNITO_USER_POOL_ID=us-east-1_nTZpyinXc,
    COGNITO_CLIENT_ID=5fpck32uhi8m87b5tkirvaf0iu,
    FILES_BUCKET=concert-prod-web-123456789012,
    EFS_MOUNT=/mnt/data
  }"
```

## Database Initialization

Run this once to create tables:

```bash
# Connect to RDS and run init.sql
# Option 1: Use Cloud9 or EC2 bastion in the same VPC
mysql -h concert-prod-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com -u concert -p concert < init.sql

# Option 2: Let Hibernate create tables on first run with ddl-auto=update (already configured above)
```

## Limitations

- **Cold Start**: 60-120 seconds on first invocation
- **Cost**: Lambda charged for full initialization time
- **Timeout**: Set to 120s (max practical for API Gateway is 30s)
- **Not Recommended**: Traditional Spring Boot is NOT optimized for Lambda

## Better Alternatives

1. **ECS Fargate** (Recommended): No cold starts, better for traditional Spring apps
2. **Spring Native + GraalVM**: Sub-second cold starts
3. **Spring Cloud Function**: Optimized for Lambda

See `ECS_FARGATE_DEPLOYMENT.md` for Fargate alternative.
