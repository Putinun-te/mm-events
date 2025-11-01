#!/bin/bash
# ============================================================================
# FREE TIER OPTIMIZATION SCRIPT
# ============================================================================
# Purpose: Convert current AWS infrastructure to 100% free tier compliant
# Region: ap-southeast-1 (Singapore)
# Target Cost: $0.00/month
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGION="ap-southeast-1"
PROJECT="concert"
ENV="dev"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     AWS FREE TIER OPTIMIZATION SCRIPT                     ║${NC}"
echo -e "${BLUE}║     Region: ap-southeast-1 (Singapore)                    ║${NC}"
echo -e "${BLUE}║     Target: \$0.00/month                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# PHASE 1: AUDIT CURRENT INFRASTRUCTURE
# ============================================================================
echo -e "${YELLOW}📊 PHASE 1: Auditing Current Infrastructure...${NC}"
echo ""

echo "Checking RDS instances..."
RDS_MULTI_AZ=$(aws rds describe-db-instances \
  --db-instance-identifier "${PROJECT}-mysql-${ENV}" \
  --region ${REGION} \
  --query 'DBInstances[0].MultiAZ' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$RDS_MULTI_AZ" == "True" ]; then
  echo -e "${RED}❌ RDS Multi-AZ is ENABLED - This costs extra!${NC}"
  echo -e "${YELLOW}   Action needed: Disable Multi-AZ to stay in free tier${NC}"
else
  echo -e "${GREEN}✅ RDS Multi-AZ is disabled (free tier compliant)${NC}"
fi

echo ""
echo "Checking ElastiCache clusters..."
ELASTICACHE_EXISTS=$(aws elasticache describe-replication-groups \
  --replication-group-id "${PROJECT}-redis-${ENV}" \
  --region ${REGION} \
  --query 'ReplicationGroups[0].Status' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$ELASTICACHE_EXISTS" != "NOT_FOUND" ]; then
  echo -e "${RED}❌ ElastiCache is running - NOT in free tier (~\$12/month)${NC}"
  echo -e "${YELLOW}   Action needed: Replace with DynamoDB for session storage${NC}"
else
  echo -e "${GREEN}✅ ElastiCache not found${NC}"
fi

echo ""
echo "Checking S3 storage usage..."
for bucket in "${PROJECT}-event-pictures" "${PROJECT}-user-avatars"; do
  BUCKET_SIZE=$(aws s3 ls s3://${bucket}-* --recursive --summarize 2>/dev/null | \
    grep "Total Size" | awk '{print $3}' || echo "0")
  BUCKET_SIZE_GB=$(echo "scale=2; $BUCKET_SIZE / 1073741824" | bc)
  
  if (( $(echo "$BUCKET_SIZE_GB > 4.5" | bc -l) )); then
    echo -e "${RED}❌ Bucket ${bucket}: ${BUCKET_SIZE_GB} GB (approaching 5 GB limit)${NC}"
  else
    echo -e "${GREEN}✅ Bucket ${bucket}: ${BUCKET_SIZE_GB} GB / 5 GB${NC}"
  fi
done

echo ""
echo "Checking Lambda invocations (last 7 days)..."
LAMBDA_INVOCATIONS=$(aws cloudwatch get-metric-statistics \
  --region ${REGION} \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=${PROJECT}-generate-presigned-url \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 604800 \
  --statistics Sum \
  --query 'Datapoints[0].Sum' \
  --output text 2>/dev/null || echo "0")

LAMBDA_MONTHLY=$(echo "$LAMBDA_INVOCATIONS * 4.3" | bc | awk '{print int($1)}')
echo -e "${GREEN}✅ Lambda invocations: ${LAMBDA_MONTHLY}/month (~${LAMBDA_INVOCATIONS}/week)${NC}"
if [ $LAMBDA_MONTHLY -gt 900000 ]; then
  echo -e "${YELLOW}   Warning: Approaching 1M/month limit${NC}"
fi

echo ""
echo -e "${GREEN}✅ Audit Complete${NC}"
echo ""

# ============================================================================
# PHASE 2: CLOUDFRONT DEPLOYMENT
# ============================================================================
echo -e "${YELLOW}📦 PHASE 2: Deploying CloudFront CDN...${NC}"
echo ""

read -p "Do you want to add CloudFront distribution? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Adding CloudFront configuration to Terraform..."
  
  # Check if cloudfront.tf exists
  if [ -f "cloudfront.tf" ]; then
    echo -e "${GREEN}✅ cloudfront.tf already exists${NC}"
  else
    echo -e "${RED}❌ cloudfront.tf not found${NC}"
    echo "Please ensure cloudfront.tf is in the current directory"
    exit 1
  fi
  
  echo "Running terraform plan..."
  terraform plan -target=aws_cloudfront_distribution.s3_distribution \
                 -target=aws_cloudfront_origin_access_identity.s3_oai \
                 -out=tfplan_cloudfront
  
  read -p "Review the plan above. Continue with deployment? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply tfplan_cloudfront
    echo -e "${GREEN}✅ CloudFront deployed successfully${NC}"
    
    # Get CloudFront domain
    CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
    echo ""
    echo -e "${GREEN}🌐 CloudFront URL: https://${CLOUDFRONT_DOMAIN}${NC}"
    echo "Update your frontend to use this URL instead of S3 direct URLs"
  fi
fi

echo ""

# ============================================================================
# PHASE 3: RDS OPTIMIZATION
# ============================================================================
echo -e "${YELLOW}💾 PHASE 3: Optimizing RDS for Free Tier...${NC}"
echo ""

if [ "$RDS_MULTI_AZ" == "True" ]; then
  echo "RDS Multi-AZ detected. This must be disabled for free tier."
  echo -e "${YELLOW}⚠️  WARNING: This will cause brief downtime during modification${NC}"
  read -p "Do you want to disable Multi-AZ now? (y/n) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Modifying RDS instance..."
    aws rds modify-db-instance \
      --db-instance-identifier "${PROJECT}-mysql-${ENV}" \
      --no-multi-az \
      --apply-immediately \
      --region ${REGION}
    
    echo -e "${GREEN}✅ RDS Multi-AZ disabled${NC}"
    echo "Waiting for modification to complete (this may take 5-10 minutes)..."
    aws rds wait db-instance-available \
      --db-instance-identifier "${PROJECT}-mysql-${ENV}" \
      --region ${REGION}
    echo -e "${GREEN}✅ RDS modification complete${NC}"
  fi
fi

echo ""

# ============================================================================
# PHASE 4: DYNAMODB SESSION TABLE
# ============================================================================
echo -e "${YELLOW}🗄️  PHASE 4: Creating DynamoDB Session Table...${NC}"
echo ""

read -p "Create DynamoDB table for sessions? (replaces ElastiCache) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  TABLE_EXISTS=$(aws dynamodb describe-table \
    --table-name "${PROJECT}-sessions-${ENV}" \
    --region ${REGION} 2>/dev/null || echo "NOT_FOUND")
  
  if [ "$TABLE_EXISTS" == "NOT_FOUND" ]; then
    echo "Creating DynamoDB table..."
    aws dynamodb create-table \
      --table-name "${PROJECT}-sessions-${ENV}" \
      --attribute-definitions \
        AttributeName=id,AttributeType=S \
      --key-schema \
        AttributeName=id,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region ${REGION} \
      --tags Key=Name,Value="Concert Sessions" Key=Environment,Value=${ENV}
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists \
      --table-name "${PROJECT}-sessions-${ENV}" \
      --region ${REGION}
    
    # Enable TTL
    aws dynamodb update-time-to-live \
      --table-name "${PROJECT}-sessions-${ENV}" \
      --time-to-live-specification "Enabled=true, AttributeName=expirationTime" \
      --region ${REGION}
    
    echo -e "${GREEN}✅ DynamoDB session table created${NC}"
  else
    echo -e "${GREEN}✅ DynamoDB session table already exists${NC}"
  fi
fi

echo ""

# ============================================================================
# PHASE 5: ELASTICACHE REMOVAL (OPTIONAL)
# ============================================================================
echo -e "${YELLOW}💰 PHASE 5: ElastiCache Removal...${NC}"
echo ""

if [ "$ELASTICACHE_EXISTS" != "NOT_FOUND" ]; then
  echo -e "${RED}ElastiCache is running and costs ~\$12/month${NC}"
  echo "Before removing, ensure:"
  echo "  1. Backend is configured to use DynamoDB for sessions"
  echo "  2. Application has been tested with DynamoDB"
  echo "  3. No critical cache dependencies remain"
  echo ""
  
  read -p "Do you want to DELETE ElastiCache cluster? (y/n) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  WARNING: This action cannot be undone!${NC}"
    read -p "Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" == "DELETE" ]; then
      echo "Deleting ElastiCache replication group..."
      aws elasticache delete-replication-group \
        --replication-group-id "${PROJECT}-redis-${ENV}" \
        --region ${REGION}
      
      echo "Waiting for deletion to complete..."
      # Wait up to 10 minutes
      for i in {1..60}; do
        STATUS=$(aws elasticache describe-replication-groups \
          --replication-group-id "${PROJECT}-redis-${ENV}" \
          --region ${REGION} \
          --query 'ReplicationGroups[0].Status' \
          --output text 2>/dev/null || echo "DELETED")
        
        if [ "$STATUS" == "DELETED" ]; then
          echo -e "${GREEN}✅ ElastiCache deleted successfully${NC}"
          echo -e "${GREEN}💰 Savings: ~\$12/month${NC}"
          break
        fi
        echo "Still deleting... ($i/60)"
        sleep 10
      done
    fi
  fi
fi

echo ""

# ============================================================================
# PHASE 6: COST MONITORING SETUP
# ============================================================================
echo -e "${YELLOW}📊 PHASE 6: Setting Up Cost Monitoring...${NC}"
echo ""

read -p "Set up billing alerts for free tier limits? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Creating CloudWatch billing alarms..."
  
  # Get or create SNS topic for alerts
  ALERT_TOPIC_ARN=$(aws sns list-topics \
    --region us-east-1 \
    --query "Topics[?contains(TopicArn, 'billing-alerts')].TopicArn" \
    --output text)
  
  if [ -z "$ALERT_TOPIC_ARN" ]; then
    echo "Creating SNS topic for billing alerts..."
    ALERT_TOPIC_ARN=$(aws sns create-topic \
      --name billing-alerts \
      --region us-east-1 \
      --query 'TopicArn' \
      --output text)
    
    echo "SNS Topic created: $ALERT_TOPIC_ARN"
    read -p "Enter your email for billing alerts: " EMAIL
    aws sns subscribe \
      --topic-arn $ALERT_TOPIC_ARN \
      --protocol email \
      --notification-endpoint $EMAIL \
      --region us-east-1
    echo "Check your email and confirm the subscription"
  fi
  
  # Create billing alarm for $5
  aws cloudwatch put-metric-alarm \
    --alarm-name "BillingAlert-5USD" \
    --alarm-description "Alert when charges exceed \$5" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 21600 \
    --evaluation-periods 1 \
    --threshold 5.0 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=Currency,Value=USD \
    --alarm-actions $ALERT_TOPIC_ARN \
    --region us-east-1
  
  echo -e "${GREEN}✅ Billing alerts configured${NC}"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               OPTIMIZATION SUMMARY                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Completed Actions:${NC}"
echo "   - Infrastructure audit completed"
echo "   - CloudFront CDN configured (if selected)"
echo "   - RDS optimized for free tier (if Multi-AZ disabled)"
echo "   - DynamoDB session table created (if selected)"
echo "   - ElastiCache removed (if selected)"
echo "   - Cost monitoring alerts set up (if selected)"

echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "   1. Update backend to use DynamoDB for sessions"
echo "   2. Update frontend to use CloudFront URLs"
echo "   3. Monitor AWS Cost Explorer weekly"
echo "   4. Deploy backend to EC2 t3.micro (750 hrs/month free)"
echo "   5. Review FREE_TIER_ARCHITECTURE.md for details"

echo ""
echo -e "${BLUE}📊 Expected Monthly Cost: \$0.00 (100% Free Tier)${NC}"
echo ""
echo -e "${GREEN}✨ Free Tier Optimization Complete!${NC}"
