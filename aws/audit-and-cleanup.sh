#!/bin/bash

REGION="ap-southeast-1"

echo "🔍 Auditing AWS Resources in $REGION..."
echo ""

# EC2 Instances
echo "=== EC2 INSTANCES ==="
aws ec2 describe-instances --region $REGION \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# S3 Buckets
echo ""
echo "=== S3 BUCKETS ==="
aws s3 ls

# CloudFront Distributions
echo ""
echo "=== CLOUDFRONT DISTRIBUTIONS ==="
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Enabled,Status]' --output table

# ELB/ALB
echo ""
echo "=== LOAD BALANCERS ==="
aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code]' --output table

# RDS
echo ""
echo "=== RDS INSTANCES ==="
aws rds describe-db-instances --region $REGION --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' --output table

# NAT Gateways (expensive!)
echo ""
echo "=== NAT GATEWAYS (💰 EXPENSIVE) ==="
aws ec2 describe-nat-gateways --region $REGION --query 'NatGateways[*].[NatGatewayId,State,VpcId]' --output table

# Elastic IPs
echo ""
echo "=== ELASTIC IPs ==="
aws ec2 describe-addresses --region $REGION --query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' --output table

# EKS Clusters
echo ""
echo "=== EKS CLUSTERS ==="
aws eks list-clusters --region $REGION --output table

echo ""
echo "💡 CLEANUP RECOMMENDATIONS:"
echo ""
echo "1. Keep: EKS cluster (concert-cluster-v2) - needed for backend"
echo "2. Keep: S3 bucket (concert-frontend-1763745483) - for frontend"
echo "3. Delete: Old CloudFront distributions if any"
echo "4. Delete: Unused NAT Gateways (\$0.045/hour = \$32/month each)"
echo "5. Delete: Unattached Elastic IPs (\$0.005/hour)"
echo "6. Delete: Old S3 buckets"
echo ""
echo "Run cleanup? (y/n)"
read -r CONFIRM

if [ "$CONFIRM" != "y" ]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "🧹 Starting cleanup..."

# Delete unused Elastic IPs
echo "Releasing unattached Elastic IPs..."
for alloc_id in $(aws ec2 describe-addresses --region $REGION --query 'Addresses[?AssociationId==null].AllocationId' --output text); do
  echo "  Releasing: $alloc_id"
  aws ec2 release-address --allocation-id $alloc_id --region $REGION 2>/dev/null || true
done

# List old S3 buckets for manual review
echo ""
echo "📦 S3 Buckets to review:"
aws s3 ls | grep -v "concert-frontend-1763745483"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💰 Current monthly costs estimate:"
echo "  - EKS (2x t4g.medium): ~\$48"
echo "  - S3 + CloudFront: ~\$1-5"
echo "  - NAT Gateway (if any): ~\$32 each"
echo "  - Total: ~\$50-100/month"
