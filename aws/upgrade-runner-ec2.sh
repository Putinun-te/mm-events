#!/bin/bash
set -e

echo "🔄 Upgrading Runner EC2 to Amazon Linux 2023"

REGION="ap-southeast-1"
OLD_INSTANCE="i-00b60427a419804ef"
KEY_NAME="concert-singapore"
SECURITY_GROUP="sg-084b6867a012f9a89"
SUBNET_ID=$(aws ec2 describe-instances --instance-ids $OLD_INSTANCE --region $REGION --query 'Reservations[0].Instances[0].SubnetId' --output text)

echo "📋 Current instance: $OLD_INSTANCE"
echo "🔑 Key: $KEY_NAME"
echo "🔒 Security Group: $SECURITY_GROUP"
echo "🌐 Subnet: $SUBNET_ID"

# Get latest AL2023 ARM64 AMI
AMI_ID=$(aws ec2 describe-images --region $REGION \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-arm64" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

echo "💿 AMI: $AMI_ID (Amazon Linux 2023 ARM64)"

# Create new instance
echo "🚀 Launching new EC2 instance..."
NEW_INSTANCE=$(aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI_ID \
  --instance-type t4g.micro \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --subnet-id $SUBNET_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=github-runner-al2023}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ New instance: $NEW_INSTANCE"
echo "⏳ Waiting for instance to be running..."

aws ec2 wait instance-running --region $REGION --instance-ids $NEW_INSTANCE

NEW_IP=$(aws ec2 describe-instances --region $REGION --instance-ids $NEW_INSTANCE --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "✅ Instance running at: $NEW_IP"
echo "⏳ Waiting 60s for SSH to be ready..."
sleep 60

echo ""
echo "📝 Next Steps:"
echo "1. SSH to new instance: ssh -i $KEY_NAME.pem ec2-user@$NEW_IP"
echo "2. Install runner:"
echo "   mkdir actions-runner && cd actions-runner"
echo "   curl -o actions-runner-linux-arm64-2.329.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-arm64-2.329.0.tar.gz"
echo "   tar xzf ./actions-runner-linux-arm64-2.329.0.tar.gz"
echo "   ./config.sh --url https://github.com/MorningMores/develop --token YOUR_TOKEN"
echo "   sudo ./svc.sh install"
echo "   sudo ./svc.sh start"
echo ""
echo "3. Terminate old instance: aws ec2 terminate-instances --instance-ids $OLD_INSTANCE"
echo ""
echo "New Instance ID: $NEW_INSTANCE"
echo "New IP: $NEW_IP"
