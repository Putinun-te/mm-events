#!/bin/bash
# Create dedicated EC2 instance for GitHub runner (separate from EKS)

# Get VPC and subnet from existing instances
VPC_ID=$(aws ec2 describe-instances --instance-ids i-021328b8eb58f98f1 --query 'Reservations[0].Instances[0].VpcId' --output text)
SUBNET_ID=$(aws ec2 describe-instances --instance-ids i-021328b8eb58f98f1 --query 'Reservations[0].Instances[0].SubnetId' --output text)

echo "Creating GitHub runner EC2 (separate from EKS)..."
echo "VPC: $VPC_ID"
echo "Subnet: $SUBNET_ID"

# Use existing security group
SG_ID="sg-084b6867a012f9a89"
echo "Using existing Security Group: $SG_ID"
echo ""
# Create t4g.medium instance (ARM-based, cheaper)
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-02a820678ae49fa85 \
  --instance-type t4g.medium \
  --key-name concert-singapore \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=github-runner-dedicated},{Key=Purpose,Value=CI-Runner}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "Created EC2 instance: $INSTANCE_ID"
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "Instance ready! Public IP: $PUBLIC_IP"
echo ""
echo "Next: SSH and setup runner:"
echo "ssh -i concert-key.pem ec2-user@$PUBLIC_IP"
echo "curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup-ec2-runner.sh"
echo "chmod +x setup-ec2-runner.sh && ./setup-ec2-runner.sh"