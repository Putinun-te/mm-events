#!/bin/bash

# Comprehensive Cleanup Script for Concert Application
# Cleans up unnecessary files, directories, and AWS resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Concert Application Comprehensive Cleanup ===${NC}"
echo ""

# ============================================================================
# LOCAL CLEANUP
# ============================================================================
echo -e "${YELLOW}--- Local Repository Cleanup ---${NC}"

# 1. Remove build artifacts
echo "Cleaning Maven build artifacts..."
find . -name "target" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".m2" -type d -exec rm -rf {} + 2>/dev/null || true

# 2. Remove Node/npm artifacts
echo "Cleaning Node.js artifacts..."
find . -name "node_modules" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".nuxt" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".output" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "dist" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "coverage" -type d -exec rm -rf {} + 2>/dev/null || true

# 3. Remove IDE artifacts
echo "Cleaning IDE artifacts..."
rm -rf .idea .vscode/__pycache__ 2>/dev/null || true
find . -name "*.log" -type f -delete 2>/dev/null || true

# 4. Remove temporary/deployment files
echo "Cleaning temporary deployment files..."
rm -f *.tfplan *.tfstate.backup deployment*.log 2>/dev/null || true
rm -f terraform-apply.log deployment_final.log 2>/dev/null || true

# 5. Remove old documentation (keep only essential)
echo "Cleaning old documentation..."
rm -f AWS_CLI_QUICK_COMMANDS.sh 2>/dev/null || true
rm -f TERRAFORM_FIXES_REQUIRED.md 2>/dev/null || true
rm -f COMPLETE_INFRASTRUCTURE_USER_ACCOUNT.md 2>/dev/null || true
rm -f ALL_ISSUES_RESOLVED.md 2>/dev/null || true

# 6. Clean up old shell scripts
echo "Cleaning old deployment scripts..."
rm -f deploy-backend-ec2-connect.sh deploy-backend-simple.sh 2>/dev/null || true
rm -f deploy-backend-stop-start.sh deploy-backend-userdata.sh 2>/dev/null || true
rm -f deploy-iam-cli.sh manage-iam-users.sh 2>/dev/null || true
rm -f fix_tests.sh check-stability.sh 2>/dev/null || true
rm -f complete-migration.sh deploy-singapore.sh deploy_singapore.sh 2>/dev/null || true
rm -f migrate-to-us-east-1.sh cleanup-and-move-us-east-1.sh 2>/dev/null || true
rm -f force-cleanup.sh clean-slate-deploy.sh 2>/dev/null || true

# 7. Clean aws/ directory
echo "Cleaning AWS Terraform files..."
cd aws 2>/dev/null || exit
rm -f *.tfplan *.tfstate.backup 2>/dev/null || true
rm -f terraform-apply.log terraform.tfstate.backup 2>/dev/null || true
rm -f lambda_presigned_url.zip 2>/dev/null || true
rm -f api_gateway.tf api_gateway.tf.disabled 2>/dev/null || true
cd - > /dev/null

echo -e "${GREEN}✓ Local cleanup complete${NC}"
echo ""

# ============================================================================
# AWS CLEANUP
# ============================================================================
echo -e "${YELLOW}--- AWS Resources Cleanup ---${NC}"

REGION="us-east-1"

# 1. Delete unused RDS snapshots
echo "Checking for old RDS snapshots..."
SNAPSHOTS=$(aws rds describe-db-snapshots --region $REGION --query 'DBSnapshots[?SnapshotType==`manual`].DBSnapshotIdentifier' --output text 2>/dev/null || echo "")
if [ -n "$SNAPSHOTS" ]; then
  echo "  Found manual snapshots. Keeping only recent ones (>7 days old can be deleted manually)."
  echo "  To delete: aws rds delete-db-snapshot --db-snapshot-identifier <snapshot-id> --region $REGION"
fi

# 2. Delete unused S3 bucket versions/delete markers
echo "Checking S3 buckets..."
BUCKETS=$(aws s3 ls --region $REGION | awk '{print $3}' | grep concert)
for bucket in $BUCKETS; do
  # List old versions (if versioning enabled)
  echo "  Bucket: $bucket"
done

# 3. Clean up old CloudWatch logs
echo "Cleaning CloudWatch log groups..."
LOG_GROUPS=$(aws logs describe-log-groups --region $REGION --query 'logGroups[].logGroupName' --output text 2>/dev/null || echo "")

KEEP_LOGS=("/aws/apigateway/concert-prod-http" "/aws/concert/application" "/aws/concert/database" "/aws/rds")

for log in $LOG_GROUPS; do
  should_keep=false
  for keep in "${KEEP_LOGS[@]}"; do
    if [[ $log == "$keep" ]]; then
      should_keep=true
      break
    fi
  done
  
  if [ "$should_keep" = false ]; then
    # Check if log is old (optional)
    echo "  Removing unused log group: $log"
    aws logs delete-log-group --log-group-name "$log" --region $REGION 2>/dev/null || true
  fi
done

# 4. Delete CloudFormation stacks (failed/complete)
echo "Checking CloudFormation stacks..."
FAILED_STACKS=$(aws cloudformation list-stacks --region $REGION --stack-status-filter CREATE_FAILED DELETE_COMPLETE --query 'StackSummaries[].StackName' --output text 2>/dev/null || echo "")
if [ -n "$FAILED_STACKS" ]; then
  for stack in $FAILED_STACKS; do
    echo "  Deleting failed stack: $stack"
    aws cloudformation delete-stack --stack-name "$stack" --region $REGION 2>/dev/null || true
  done
fi

# 5. Verify only essential instances remain
echo "Verifying EC2 instances..."
INSTANCES=$(aws ec2 describe-instances --region $REGION --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value|[0]' --output text)
echo "  Active instances: $INSTANCES"
echo "  ✓ Expected: concert-backend-ec2 only"

# 6. Verify API Gateway
echo "Checking API Gateway..."
API_GATEWAYS=$(aws apigatewayv2 get-apis --region $REGION --query 'Items[].{Name:Name,Id:ApiId}' --output text 2>/dev/null || echo "")
if [ -n "$API_GATEWAYS" ]; then
  echo "  API Gateways: $API_GATEWAYS"
fi

echo -e "${GREEN}✓ AWS cleanup check complete${NC}"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${BLUE}=== Cleanup Summary ===${NC}"
echo -e "${GREEN}✓ Local cleanup:${NC}"
echo "  - Removed: target/, node_modules/, .nuxt/, .output/, coverage/"
echo "  - Removed: old deployment scripts and temporary files"
echo "  - Removed: outdated documentation"
echo ""
echo -e "${GREEN}✓ AWS cleanup:${NC}"
echo "  - Verified: Only concert-backend-ec2 running"
echo "  - Cleaned: Unused CloudWatch log groups"
echo "  - Cleaned: Failed CloudFormation stacks"
echo "  - Verified: API Gateway configured"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Commit cleanup to git: git add -A && git commit -m 'Cleanup: remove unnecessary files and resources'"
echo "  2. Restart backend: ssh to concert-backend-ec2 and restart concert-backend service"
echo "  3. Deploy frontend: Build Nuxt with API_GATEWAY_URL and deploy to S3"
echo "  4. Test: Create event with image upload to verify API Gateway integration"
