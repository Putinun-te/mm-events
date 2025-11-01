# 🚀 AWS SERVICES DEPLOYMENT GUIDE - COMPLETE IMPLEMENTATION

**Date:** October 31, 2025  
**Status:** Ready for Deployment  
**All Systems:** Integrated and Production-Ready

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Detailed Deployment](#detailed-deployment)
3. [Service Integration](#service-integration)
4. [Verification Checklist](#verification-checklist)
5. [Troubleshooting](#troubleshooting)
6. [Post-Deployment](#post-deployment)

---

## ⚡ Quick Start

### Prerequisites
```bash
# Install required tools
brew install terraform aws-cli
aws configure  # Configure AWS credentials

# Set environment
export AWS_REGION=us-east-1
export ENVIRONMENT=dev  # or test/staging/prod
```

### Deploy Everything (5 minutes)
```bash
cd /Users/putinan/development/DevOps/develop/aws

# 1. Initialize Terraform
terraform init

# 2. Create plan
terraform plan -out=tfplan

# 3. Review and apply
terraform apply tfplan
```

---

## 🏗️ Detailed Deployment

### Phase 1: Infrastructure Foundation (15 minutes)

#### Step 1: Deploy VPC & Networking
```bash
cd aws/

# Validate Terraform
terraform validate

# Plan networking resources
terraform plan -target=aws_vpc.concert \
              -target=aws_subnet.public_1 \
              -target=aws_subnet.public_2 \
              -target=aws_subnet.private_1 \
              -target=aws_subnet.private_2 \
              -out=tfplan_network

# Deploy
terraform apply tfplan_network

# Verify
aws ec2 describe-vpcs --filters Name=tag:Name,Values=concert-vpc-dev
```

#### Step 2: Deploy RDS MySQL Database
```bash
# Plan RDS
terraform plan -target=aws_db_instance.concert \
              -target=aws_db_subnet_group.concert \
              -target=aws_secretsmanager_secret.rds_credentials \
              -out=tfplan_rds

# Deploy
terraform apply tfplan_rds

# Wait for RDS to be ready (5-10 minutes)
aws rds describe-db-instances --db-instance-identifier concert-mysql-dev

# Retrieve endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier concert-mysql-dev \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"
```

#### Step 3: Deploy DynamoDB Tables
```bash
# Plan DynamoDB
terraform plan -target=aws_dynamodb_table.session_tokens \
              -target=aws_dynamodb_table.event_details \
              -target=aws_dynamodb_table.booking_cache \
              -target=aws_dynamodb_table.user_preferences \
              -target=aws_dynamodb_table.file_metadata \
              -target=aws_dynamodb_table.email_log \
              -target=aws_dynamodb_table.payment_cache \
              -target=aws_dynamodb_table.analytics_events \
              -target=aws_dynamodb_table.audit_cache \
              -out=tfplan_dynamodb

# Deploy
terraform apply tfplan_dynamodb

# Verify
aws dynamodb list-tables --query 'TableNames' | grep concert
```

#### Step 4: Deploy ElastiCache Redis
```bash
# Plan ElastiCache
terraform plan -target=aws_elasticache_replication_group.concert \
              -target=aws_elasticache_parameter_group.concert \
              -target=aws_elasticache_subnet_group.concert \
              -out=tfplan_elasticache

# Deploy
terraform apply tfplan_elasticache

# Wait for ElastiCache (10-15 minutes)
aws elasticache describe-replication-groups \
  --replication-group-id concert-redis-dev

# Get endpoint
REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
  --replication-group-id concert-redis-dev \
  --query 'ReplicationGroups[0].ConfigurationEndpoint.Address' \
  --output text)

echo "Redis Endpoint: $REDIS_ENDPOINT"
```

#### Step 5: Deploy SNS & SQS Messaging
```bash
# Plan Messaging
terraform plan -target=aws_sns_topic.notifications \
              -target=aws_sns_topic.email \
              -target=aws_sns_topic.sms \
              -target=aws_sqs_queue.email_queue \
              -target=aws_sqs_queue.notification_queue \
              -target=aws_sqs_queue.refund_queue \
              -target=aws_sqs_queue.analytics_queue \
              -out=tfplan_messaging

# Deploy
terraform apply tfplan_messaging

# Verify
aws sns list-topics | grep concert
aws sqs list-queues --query 'QueueUrls' | grep concert
```

### Phase 2: Lambda Services Deployment (20 minutes)

#### Step 1: Create Lambda Execution Role
```bash
# Create role that Lambda functions will use
aws iam create-role \
  --role-name concert-lambda-execution-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policies
aws iam attach-role-policy \
  --role-name concert-lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

aws iam attach-role-policy \
  --role-name concert-lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

#### Step 2: Package Lambda Functions
```bash
# Create deployment package
cd aws/lambda

# Create layer for dependencies
mkdir -p python/lib/python3.11/site-packages

# Install dependencies
pip install -r requirements.txt -t python/lib/python3.11/site-packages/

# Create layer zip
zip -r python_layer.zip python/

# Upload to S3
aws s3 cp python_layer.zip s3://concert-lambda-layer-dev/

# Create function zips
for service in auth_service event_service booking_service s3_file_service email_service notification_service analytics_service cache_service audit_service payment_service; do
    cd services
    zip -r ../${service}.zip ${service}.py
    cd ..
done

# Upload to S3
aws s3 cp *.zip s3://concert-lambda-functions-dev/
```

#### Step 3: Deploy Individual Lambda Functions
```bash
# 1. AUTH SERVICE
aws lambda create-function \
  --function-name concert-auth-service-dev \
  --runtime python3.11 \
  --role arn:aws:iam::ACCOUNT_ID:role/concert-lambda-execution-role \
  --handler auth_service.lambda_handler \
  --code S3Bucket=concert-lambda-functions-dev,S3Key=auth_service.zip \
  --environment Variables="{ENVIRONMENT=dev,JWT_SECRET=your-secret}" \
  --vpc-config SubnetIds=subnet-xxx,SecurityGroupIds=sg-xxx \
  --timeout 30 \
  --memory-size 512 \
  --tags Environment=dev,Service=auth

# 2. EVENT SERVICE
aws lambda create-function \
  --function-name concert-event-service-dev \
  --runtime python3.11 \
  --role arn:aws:iam::ACCOUNT_ID:role/concert-lambda-execution-role \
  --handler event_service.lambda_handler \
  --code S3Bucket=concert-lambda-functions-dev,S3Key=event_service.zip \
  --vpc-config SubnetIds=subnet-xxx,SecurityGroupIds=sg-xxx \
  --timeout 30 \
  --memory-size 512 \
  --tags Environment=dev,Service=event

# Repeat for remaining 8 services...
# (booking, s3_file, email, notification, analytics, cache, audit, payment)
```

#### Step 4: Configure Lambda Environment Variables
```bash
# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier concert-mysql-dev \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Get Redis endpoint
REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
  --replication-group-id concert-redis-dev \
  --query 'ReplicationGroups[0].ConfigurationEndpoint.Address' \
  --output text)

# Get SNS topic ARNs
SNS_TOPIC=$(aws sns list-topics --query 'Topics[?contains(TopicArn, `concert-events`)].TopicArn' --output text)

# Update each function
for service in auth event booking s3_file email notification analytics cache audit payment; do
    aws lambda update-function-configuration \
      --function-name concert-${service}-service-dev \
      --environment Variables="{
        ENVIRONMENT=dev,
        RDS_HOST=${RDS_ENDPOINT},
        RDS_USER=admin,
        REDIS_ENDPOINT=${REDIS_ENDPOINT},
        SNS_TOPIC=${SNS_TOPIC},
        DYNAMODB_REGION=us-east-1
      }"
done
```

### Phase 3: API Gateway Setup (10 minutes)

#### Step 1: Create API Gateway
```bash
# Create REST API
API_ID=$(aws apigateway create-rest-api \
  --name concert-api-dev \
  --description "Concert Application API" \
  --query 'id' \
  --output text)

echo "API ID: $API_ID"
```

#### Step 2: Create Resources and Methods
```bash
# Get root resource
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --query 'items[0].id' \
  --output text)

# Create /api resource
API_RESOURCE=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part api \
  --query 'id' \
  --output text)

# Create /auth resource
AUTH_RESOURCE=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $API_RESOURCE \
  --path-part auth \
  --query 'id' \
  --output text)

# Create POST method for /auth/login
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE \
  --http-method POST \
  --authorization-type NONE

# Create integration with Lambda
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT_ID:function:concert-auth-service-dev/invocations
```

#### Step 3: Deploy API
```bash
# Create deployment
DEPLOYMENT_ID=$(aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name dev \
  --query 'id' \
  --output text)

echo "Deployment ID: $DEPLOYMENT_ID"

# Get API endpoint
API_ENDPOINT=$(aws apigateway get-stage \
  --rest-api-id $API_ID \
  --stage-name dev \
  --query 'invokeUrl' \
  --output text)

echo "API Endpoint: $API_ENDPOINT"
```

### Phase 4: Database Schema Setup (5 minutes)

```bash
# Connect to RDS MySQL
mysql -h $RDS_ENDPOINT -u admin -p concert_db < database_schema.sql

# Verify tables created
mysql -h $RDS_ENDPOINT -u admin -p concert_db -e "SHOW TABLES;"
```

---

## 🔗 Service Integration

### Lambda → RDS Connection
```python
import pymysql

def get_rds_connection():
    return pymysql.connect(
        host=os.environ['RDS_HOST'],
        user=os.environ['RDS_USER'],
        password=os.environ['RDS_PASSWORD'],
        database='concert_db'
    )
```

### Lambda → DynamoDB Integration
```python
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('concert-session-tokens-dev')

table.get_item(Key={'token_id': 'token-123'})
table.put_item(Item={'token_id': 'token-123', 'user_id': 'user-456'})
```

### Lambda → Redis Integration
```python
import redis

redis_client = redis.Redis(
    host=os.environ['REDIS_ENDPOINT'],
    port=6379,
    decode_responses=True
)

redis_client.set('key', 'value', ex=3600)
redis_client.get('key')
```

### Lambda → SNS Integration
```python
import boto3

sns = boto3.client('sns')

sns.publish(
    TopicArn=os.environ['SNS_TOPIC'],
    Subject='Event Notification',
    Message='Event data here'
)
```

### Lambda → SQS Integration
```python
import boto3

sqs = boto3.client('sqs')

sqs.send_message(
    QueueUrl=os.environ['SQS_QUEUE_URL'],
    MessageBody=json.dumps({'data': 'here'})
)
```

---

## ✅ Verification Checklist

### Infrastructure Verification
- [ ] VPC created and subnets available
- [ ] RDS instance running (check status)
- [ ] DynamoDB tables exist (all 9 tables)
- [ ] ElastiCache Redis cluster available
- [ ] SNS topics created (5 topics)
- [ ] SQS queues created (5 queues)
- [ ] Security groups configured
- [ ] VPC endpoints working

### Lambda Verification
- [ ] All 10 Lambda functions created
- [ ] IAM roles attached
- [ ] Environment variables set
- [ ] VPC configuration correct
- [ ] Layers attached
- [ ] Logging enabled

### API Gateway Verification
- [ ] API created
- [ ] Resources structured
- [ ] Methods configured
- [ ] Authorizers working
- [ ] CORS enabled
- [ ] Deployment successful

### Connectivity Verification
```bash
# Test RDS connection
aws lambda invoke \
  --function-name concert-auth-service-dev \
  --payload '{"test": "connection"}' \
  response.json
cat response.json

# Test DynamoDB access
aws dynamodb scan --table-name concert-session-tokens-dev

# Test Redis connectivity
aws elasticache test-replication-group-message-delivery \
  --replication-group-id concert-redis-dev

# Test SNS publishing
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:concert-notifications-dev \
  --message "Test message"

# Test SQS queue
aws sqs send-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/concert-email-queue-dev \
  --message-body "Test message"
```

### Load Testing
```bash
# Install Apache Bench
brew install httpd

# Test API endpoint
ab -n 1000 -c 10 https://API_ENDPOINT/api/events
```

---

## 🔧 Troubleshooting

### Issue: Lambda Cannot Connect to RDS
**Solution:**
```bash
# Check Lambda security group
aws ec2 describe-security-groups --group-ids sg-lambda

# Check RDS security group rules
aws ec2 describe-security-groups --group-ids sg-rds

# Verify RDS security group allows Lambda
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp \
  --port 3306 \
  --source-group sg-lambda
```

### Issue: Lambda Timeout
**Solution:**
```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name concert-auth-service-dev \
  --timeout 60
```

### Issue: DynamoDB Throttling
**Solution:**
```bash
# Enable auto-scaling
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/concert-event-details-dev \
  --scalable-dimension dynamodb:table:WriteCapacityUnits \
  --min-capacity 10 \
  --max-capacity 40
```

### Issue: Redis Connection Refused
**Solution:**
```bash
# Check cluster status
aws elasticache describe-replication-groups \
  --replication-group-id concert-redis-dev

# Check security group
aws ec2 describe-security-groups --group-ids sg-redis

# Authorize Lambda
aws ec2 authorize-security-group-ingress \
  --group-id sg-redis \
  --protocol tcp \
  --port 6379 \
  --source-group sg-lambda
```

---

## 📈 Post-Deployment

### 1. CloudWatch Monitoring
```bash
# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name Concert-Dashboard-Dev \
  --dashboard-body file://dashboard.json
```

### 2. CloudWatch Alarms
```bash
# Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name concert-lambda-errors \
  --alarm-description "Lambda function errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

### 3. CloudTrail Logging
```bash
# Enable CloudTrail
aws cloudtrail start-logging --trail-name concert-trail
```

### 4. Testing Services

#### Test Auth Service
```bash
curl -X POST https://API_ENDPOINT/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

#### Test Event Service
```bash
curl -X GET https://API_ENDPOINT/api/events \
  -H "Authorization: Bearer $TOKEN"
```

#### Test File Upload
```bash
curl -X POST https://API_ENDPOINT/api/files/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@document.pdf"
```

### 5. Performance Benchmarking
```bash
# Run load test
ab -n 10000 -c 100 https://API_ENDPOINT/api/events

# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --start-time 2025-10-31T00:00:00Z \
  --end-time 2025-11-01T00:00:00Z \
  --period 3600 \
  --statistics Average,Maximum
```

### 6. Security Hardening
```bash
# Enable WAF on API Gateway
# Add rate limiting policies
# Enable CloudTrail logging
# Set up VPC Flow Logs
# Configure IAM policies for least privilege
# Rotate secrets in Secrets Manager
```

---

## 📊 Cost Optimization

### Production Settings (Recommended for Cost)

**RDS:**
- Reserved Instances (3-year commitment)
- Read replicas for scaling
- Storage auto-scaling

**DynamoDB:**
- Use provisioned billing (predictable load)
- Global secondary indexes only when needed
- TTL for automatic cleanup

**Lambda:**
- Provisioned concurrency for predictable traffic
- Reserved concurrency limits
- Optimize memory allocation

**ElastiCache:**
- Reserved nodes
- Cluster mode for distribution
- Appropriate node type selection

**Estimated Monthly Cost:**
- RDS: $150-300
- DynamoDB: $50-100
- Lambda: $50-200
- ElastiCache: $100-200
- API Gateway: $50-100
- Data Transfer: $20-50
- **Total: $420-950/month**

---

## 🎉 Success Criteria

✅ All infrastructure deployed  
✅ 10 Lambda services running  
✅ API Gateway responding to requests  
✅ RDS MySQL accessible  
✅ DynamoDB tables populated  
✅ ElastiCache Redis operational  
✅ SNS/SQS messaging working  
✅ CloudWatch monitoring active  
✅ Load tests passing  
✅ Security audit passed  

---

**Status:** ✅ Ready for Production  
**Maintenance:** DevOps Team  
**Last Updated:** October 31, 2025
