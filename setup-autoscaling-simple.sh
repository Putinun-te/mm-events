#!/bin/bash
set -e

REGION="ap-southeast-1"
INSTANCE_ID="i-0ffd487469a6fa1aa"

echo "🚀 Setting up Auto Scaling..."

# Get details
VPC_ID=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')
SG=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

# Create Launch Template
cat > /tmp/lt-data.json <<'EOF'
{
  "ImageId": "ami-029ad316e58237cd4",
  "InstanceType": "t3.small",
  "SecurityGroupIds": ["SG_PLACEHOLDER"],
  "UserData": "IyEvYmluL2Jhc2gKYXdzIGVjciBnZXQtbG9naW4tcGFzc3dvcmQgLS1yZWdpb24gdXMtZWFzdC0xIHwgZG9ja2VyIGxvZ2luIC0tdXNlcm5hbWUgQVdTIC0tcGFzc3dvcmQtc3RkaW4gMTYxMzI2MjQwMzQ3LmRrci5lY3IudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20KZG9ja2VyIHB1bGwgMTYxMzI2MjQwMzQ3LmRrci5lY3IudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20vY29uY2VydC1hcGk6Y29ycy1maXgKZG9ja2VyIHJ1biAtZCAtcCA4MDgwOjgwODAgLWUgU1BSSU5HX0RBVEFTT1VSQ0VfVVJMPWpkYmM6bXlzcWw6Ly9jb25jZXJ0LXByb2QtZGIuY3B5MDhveWlxMm41LmFwLXNvdXRoZWFzdC0xLnJkcy5hbWF6b25hd3MuY29tOjMzMDYvY29uY2VydF9kYiAtZSBTUFJJTkdfREFUQVNPVVJDRV9VU0VSTkFNRT1hZG1pbiAtZSBTUFJJTkdfREFUQVNPVVJDRV9QQVNTV09SRD1Db25jZXJ0MjAyNCEgLWUgQVdTX1JFR0lPTj11cy1lYXN0LTEgLS1yZXN0YXJ0IHVubGVzcy1zdG9wcGVkIDE2MTMyNjI0MDM0Ny5ka3IuZWNyLnVzLWVhc3QtMS5hbWF6b25hd3MuY29tL2NvbmNlcnQtYXBpOmNvcnMtZml4"
}
EOF

sed -i '' "s/SG_PLACEHOLDER/$SG/" /tmp/lt-data.json

aws ec2 create-launch-template \
  --region $REGION \
  --launch-template-name concert-backend-lt \
  --launch-template-data file:///tmp/lt-data.json 2>/dev/null || echo "Template exists"

# Create Target Group
TG_ARN=$(aws elbv2 create-target-group \
  --region $REGION \
  --name concert-asg-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --health-check-path /api/auth/test \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || aws elbv2 describe-target-groups --region $REGION --names concert-asg-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create ASG
aws autoscaling create-auto-scaling-group \
  --region $REGION \
  --auto-scaling-group-name concert-asg \
  --launch-template LaunchTemplateName=concert-backend-lt \
  --min-size 1 \
  --max-size 3 \
  --desired-capacity 1 \
  --vpc-zone-identifier "$SUBNET_IDS" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB \
  --health-check-grace-period 300 2>/dev/null || echo "ASG exists"

# Scaling Policy
aws autoscaling put-scaling-policy \
  --region $REGION \
  --auto-scaling-group-name concert-asg \
  --policy-name cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{"PredefinedMetricSpecification":{"PredefinedMetricType":"ASGAverageCPUUtilization"},"TargetValue":70.0}' 2>/dev/null || echo "Policy exists"

echo "✅ Auto Scaling configured: 1-3 instances, CPU target 70%"
