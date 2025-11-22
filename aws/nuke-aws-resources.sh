#!/bin/bash
set -e

echo "🔥 AWS Resource Cleanup Script"
echo "=============================="
echo "⚠️  WARNING: This will delete AWS infrastructure (NOT code)!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted"
  exit 0
fi

REGION="ap-southeast-1"

echo "📝 Note: This script only deletes AWS infrastructure"
echo "   Your code in Git repositories will NOT be affected"

# Terminate EC2 instances
echo "🔍 Finding EC2 instances..."
INSTANCES=$(aws ec2 describe-instances --region $REGION --filters "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[*].InstanceId' --output text)
if [ ! -z "$INSTANCES" ]; then
  echo "🗑️  Terminating EC2 instances: $INSTANCES"
  aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCES
fi

# Delete EKS clusters
echo "🔍 Finding EKS clusters..."
CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters' --output text)
for CLUSTER in $CLUSTERS; do
  echo "🗑️  Deleting EKS cluster: $CLUSTER"
  aws eks delete-cluster --region $REGION --name $CLUSTER || true
done

# Delete RDS instances
echo "🔍 Finding RDS instances..."
DBS=$(aws rds describe-db-instances --region $REGION --query 'DBInstances[*].DBInstanceIdentifier' --output text)
for DB in $DBS; do
  echo "🗑️  Deleting RDS: $DB"
  aws rds delete-db-instance --region $REGION --db-instance-identifier $DB --skip-final-snapshot || true
done

# Delete ElastiCache clusters
echo "🔍 Finding ElastiCache clusters..."
CACHES=$(aws elasticache describe-cache-clusters --region $REGION --query 'CacheClusters[*].CacheClusterId' --output text)
for CACHE in $CACHES; do
  echo "🗑️  Deleting ElastiCache: $CACHE"
  aws elasticache delete-cache-cluster --region $REGION --cache-cluster-id $CACHE || true
done

# Delete Load Balancers
echo "🔍 Finding Load Balancers..."
LBS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].LoadBalancerArn' --output text)
for LB in $LBS; do
  echo "🗑️  Deleting Load Balancer: $LB"
  aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn $LB || true
done

# Empty and delete S3 buckets (skip code/artifact buckets)
echo "🔍 Finding S3 buckets..."
BUCKETS=$(aws s3 ls --region $REGION | awk '{print $3}' | grep -v 'github\|artifact\|code')
for BUCKET in $BUCKETS; do
  echo "🗑️  Emptying and deleting S3 bucket: $BUCKET"
  aws s3 rm s3://$BUCKET --recursive || true
  aws s3 rb s3://$BUCKET --force || true
done

# Delete VPCs (after resources are deleted)
sleep 30
echo "🔍 Finding VPCs..."
VPCS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=isDefault,Values=false" --query 'Vpcs[*].VpcId' --output text)
for VPC in $VPCS; do
  echo "🗑️  Deleting VPC: $VPC"
  
  # Delete NAT Gateways
  NATS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=vpc-id,Values=$VPC" --query 'NatGateways[*].NatGatewayId' --output text)
  for NAT in $NATS; do
    aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id $NAT || true
  done
  
  # Delete Internet Gateways
  IGWS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC" --query 'InternetGateways[*].InternetGatewayId' --output text)
  for IGW in $IGWS; do
    aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id $IGW --vpc-id $VPC || true
    aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id $IGW || true
  done
  
  # Delete Subnets
  SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC" --query 'Subnets[*].SubnetId' --output text)
  for SUBNET in $SUBNETS; do
    aws ec2 delete-subnet --region $REGION --subnet-id $SUBNET || true
  done
  
  # Delete Security Groups
  SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
  for SG in $SGS; do
    aws ec2 delete-security-group --region $REGION --group-id $SG || true
  done
  
  # Delete VPC
  aws ec2 delete-vpc --region $REGION --vpc-id $VPC || true
done

echo "✅ Cleanup complete!"
echo "Note: Some resources may take time to fully delete"
