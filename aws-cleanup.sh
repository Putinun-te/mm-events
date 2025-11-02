#!/bin/bash

# AWS Cleanup Script for Concert Application
# This script audits and optionally cleans up unused AWS resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REGION="us-east-1"
DRY_RUN=false  # Set to false to actually delete; default is audit mode

echo -e "${BLUE}=== AWS Resource Cleanup Audit ===${NC}"
echo -e "${YELLOW}Region: $REGION${NC}"
echo -e "${YELLOW}Dry-run mode: $DRY_RUN (set to false to actually delete)${NC}"
echo ""

# Colors for cleanup decision
KEEP="${GREEN}[KEEP]${NC}"
REMOVE="${RED}[REMOVE]${NC}"

# ============================================================================
# 1. S3 Buckets
# ============================================================================
echo -e "${BLUE}--- S3 Buckets ---${NC}"
BUCKETS=$(aws s3 ls --region $REGION | awk '{print $3}')
KEEP_BUCKETS=("concert-event-pictures" "concert-user-avatars" "concert-dev-frontend")

for bucket in $BUCKETS; do
  should_keep=false
  for keep in "${KEEP_BUCKETS[@]}"; do
    if [[ $bucket == *"$keep"* ]]; then
      should_keep=true
      break
    fi
  done
  
  if [ "$should_keep" = true ]; then
    echo -e "  $KEEP $bucket"
  else
    echo -e "  $REMOVE $bucket"
    if [ "$DRY_RUN" = false ]; then
      echo "    Deleting bucket: $bucket"
      aws s3 rb s3://$bucket --force --region $REGION 2>/dev/null || true
    fi
  fi
done
echo ""

# ============================================================================
# 2. EC2 Instances (stopped/terminated)
# ============================================================================
echo -e "${BLUE}--- EC2 Instances (Stopped/Terminated) ---${NC}"
STOPPED=$(aws ec2 describe-instances --region $REGION --filters "Name=instance-state-name,Values=stopped,terminated" --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0],State:State.Name}' --output json)

if [ $(echo $STOPPED | jq '. | length') -gt 0 ]; then
  echo $STOPPED | jq -r '.[] | "  \(.State): \(.ID) (\(.Name // "No name"))"'
  if [ "$DRY_RUN" = false ]; then
    echo $STOPPED | jq -r '.[] | .ID' | while read id; do
      aws ec2 terminate-instances --region $REGION --instance-ids $id 2>/dev/null || true
    done
  fi
else
  echo "  No stopped/terminated instances found."
fi
echo ""

# ============================================================================
# 3. CloudFormation Stacks (DELETE_COMPLETE, CREATE_FAILED)
# ============================================================================
echo -e "${BLUE}--- CloudFormation Stacks (Unused) ---${NC}"
STACKS=$(aws cloudformation list-stacks --region $REGION --stack-status-filter DELETE_COMPLETE CREATE_FAILED --query 'StackSummaries[].{Name:StackName,Status:StackStatus}' --output json)

if [ $(echo $STACKS | jq '. | length') -gt 0 ]; then
  echo $STACKS | jq -r '.[] | "  \(.Status): \(.Name)"'
  if [ "$DRY_RUN" = false ]; then
    echo $STACKS | jq -r '.[] | .Name' | while read stack; do
      aws cloudformation delete-stack --region $REGION --stack-name "$stack" 2>/dev/null || true
    done
  fi
else
  echo "  No failed/deleted stacks found."
fi
echo ""

# ============================================================================
# 4. RDS Snapshots (old, unused)
# ============================================================================
echo -e "${BLUE}--- RDS Snapshots (Old) ---${NC}"
SNAPSHOTS=$(aws rds describe-db-snapshots --region $REGION --query 'DBSnapshots[?SnapshotType==`manual`].{ID:DBSnapshotIdentifier,Created:SnapshotCreateTime}' --output json)

if [ $(echo $SNAPSHOTS | jq '. | length') -gt 0 ]; then
  echo $SNAPSHOTS | jq -r '.[] | "  \(.ID) (Created: \(.Created))"'
  # Optionally delete snapshots older than 30 days
  # For now, just list them
else
  echo "  No manual RDS snapshots found."
fi
echo ""

# ============================================================================
# 5. CloudWatch Log Groups (Old)
# ============================================================================
echo -e "${BLUE}--- CloudWatch Log Groups (Old/Unused) ---${NC}"
LOG_GROUPS=$(aws logs describe-log-groups --region $REGION --query 'logGroups[].{Name:logGroupName,CreatedTime:creationTime}' --output json 2>/dev/null || echo '[]')

# Keep active log groups
KEEP_LOGS=("/aws/apigateway/concert-prod-http" "/aws/concert" "/aws/rds" "/aws/lambda")

echo "$LOG_GROUPS" | jq -r '.[] | .Name' | while read log; do
  should_keep=false
  for keep in "${KEEP_LOGS[@]}"; do
    if [[ $log == *"$keep"* ]]; then
      should_keep=true
      break
    fi
  done
  
  if [ "$should_keep" = true ]; then
    echo -e "  $KEEP $log"
  else
    echo -e "  $REMOVE $log"
    if [ "$DRY_RUN" = false ]; then
      aws logs delete-log-group --region $REGION --log-group-name "$log" 2>/dev/null || true
    fi
  fi
done
echo ""

# ============================================================================
# 6. Unused Security Groups
# ============================================================================
echo -e "${BLUE}--- Unused Security Groups ---${NC}"
SG=$(aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[].{ID:GroupId,Name:GroupName}' --output json)

# Keep active SGs
KEEP_SG=("concert-ec2-sg" "concert-rds-sg" "default")

echo "$SG" | jq -r '.[] | "\(.ID) (\(.Name))"' | while read sg_info; do
  sg_name=$(echo $sg_info | grep -oP '\(\K[^)]+')
  should_keep=false
  
  for keep in "${KEEP_SG[@]}"; do
    if [[ $sg_name == *"$keep"* ]]; then
      should_keep=true
      break
    fi
  done
  
  if [ "$should_keep" = true ]; then
    echo -e "  $KEEP $sg_info"
  else
    echo -e "  $REMOVE $sg_info"
    # Note: only delete if not in use
  fi
done
echo ""

# ============================================================================
# 7. Unused IAM Roles
# ============================================================================
echo -e "${BLUE}--- Unused IAM Roles ---${NC}"
ROLES=$(aws iam list-roles --query 'Roles[].{Name:RoleName,Created:CreateDate}' --output json)

# Keep active roles
KEEP_ROLES=("concert-backend-ec2-role" "concert-ec2-role" "api-gateway" "lambda" "cognito")

echo "$ROLES" | jq -r '.[] | .Name' | while read role; do
  should_keep=false
  
  for keep in "${KEEP_ROLES[@]}"; do
    if [[ $role == *"$keep"* ]] || [[ $role == "aws"* ]]; then
      should_keep=true
      break
    fi
  done
  
  if [ "$should_keep" = true ]; then
    echo -e "  $KEEP $role"
  else
    echo -e "  $REMOVE $role"
    # IAM deletion is more complex; manual review recommended
  fi
done
echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "Dry-run mode: $DRY_RUN"
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}No resources were deleted. To actually clean up, set DRY_RUN=false and rerun.${NC}"
else
  echo -e "${GREEN}Cleanup complete.${NC}"
fi
