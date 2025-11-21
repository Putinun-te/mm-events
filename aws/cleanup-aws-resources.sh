#!/bin/bash

REGION="ap-southeast-1"

echo "🧹 Cleaning up unnecessary AWS resources..."

# List all resources
echo "=== Current Resources ==="
echo ""
echo "EC2 Instances:"
aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table

echo ""
echo "NAT Gateways (💰 \$32/month each):"
aws ec2 describe-nat-gateways --region $REGION --query 'NatGateways[?State==`available`].[NatGatewayId,VpcId]' --output table

echo ""
echo "Elastic IPs (💰 \$3.6/month if unattached):"
aws ec2 describe-addresses --region $REGION --query 'Addresses[*].[AllocationId,PublicIp,AssociationId]' --output table

echo ""
echo "CloudFront Distributions:"
aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName,Enabled]' --output table

echo ""
echo "S3 Buckets:"
aws s3 ls

echo ""
echo "💡 Recommendations:"
echo "✅ Keep: EKS (2 nodes), RDS, S3 (3 buckets), CloudFront (1)"
echo "❌ Delete: NAT Gateways, unused EIPs, old CloudFront distributions"
