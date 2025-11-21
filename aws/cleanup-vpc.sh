#!/bin/bash

set -e

REGION="ap-southeast-1"
VPC_ID="vpc-008d426736ce4335f"
IGW_ID="igw-0664e7998c88eb297"

echo "🧹 Cleaning up VPC resources..."

# Release Elastic IPs
echo "Releasing Elastic IPs..."
for alloc_id in $(aws ec2 describe-addresses --region $REGION --filters "Name=domain,Values=vpc" --query "Addresses[?AssociationId!=null]|[?NetworkInterfaceId!=null].AllocationId" --output text); do
  echo "  Disassociating EIP: $alloc_id"
  ASSOC_ID=$(aws ec2 describe-addresses --region $REGION --allocation-ids $alloc_id --query 'Addresses[0].AssociationId' --output text)
  aws ec2 disassociate-address --association-id $ASSOC_ID --region $REGION 2>/dev/null || true
  echo "  Releasing EIP: $alloc_id"
  aws ec2 release-address --allocation-id $alloc_id --region $REGION 2>/dev/null || true
done

# Detach and delete internet gateway
echo "Detaching IGW: $IGW_ID from VPC: $VPC_ID"
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
echo "Deleting IGW: $IGW_ID"
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION 2>/dev/null || true

# Force detach and delete network interfaces
for eni in eni-01d2653ab62bbde96 eni-05780a846721d55d1 eni-002e46087abb8bd9c; do
  echo "Processing ENI: $eni"
  
  # Get attachment ID
  ATTACH_ID=$(aws ec2 describe-network-interfaces --network-interface-ids $eni --region $REGION --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text 2>/dev/null || echo "")
  
  if [ "$ATTACH_ID" != "" ] && [ "$ATTACH_ID" != "None" ]; then
    echo "  Detaching: $ATTACH_ID"
    aws ec2 detach-network-interface --attachment-id $ATTACH_ID --region $REGION --force 2>/dev/null || true
    sleep 5
  fi
  
  echo "  Deleting: $eni"
  aws ec2 delete-network-interface --network-interface-id $eni --region $REGION 2>/dev/null || true
done

# Delete subnets
for subnet in subnet-0a14aca8da156e6cd subnet-04dedf3f9e3f95194 subnet-077be955865b076ac; do
  echo "Deleting subnet: $subnet"
  aws ec2 delete-subnet --subnet-id $subnet --region $REGION 2>/dev/null || true
done

# Delete VPC
echo "Deleting VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null || true

echo "✅ VPC cleanup complete!"
echo ""
echo "Now delete the CloudFormation stack:"
echo "aws cloudformation delete-stack --stack-name eksctl-concert-cluster-cluster --region $REGION"
