#!/bin/bash
set -e

REGION="ap-southeast-1"
INSTANCE_ID="i-0ffd487469a6fa1aa"

echo "🚀 Setting up Auto Scaling for Concert Backend..."

# Get instance details
VPC_ID=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')
SECURITY_GROUPS=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' --output text | tr '\t' ',')
IMAGE_ID=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].ImageId' --output text)
INSTANCE_TYPE=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].InstanceType' --output text)

echo "📋 Instance Details:"
echo "  VPC: $VPC_ID"
echo "  Subnets: $SUBNET_IDS"
echo "  Security Groups: $SECURITY_GROUPS"
echo "  AMI: $IMAGE_ID"
echo "  Instance Type: $INSTANCE_TYPE"

# Create Launch Template
echo "📝 Creating Launch Template..."
LAUNCH_TEMPLATE=$(aws ec2 create-launch-template \
  --region $REGION \
  --launch-template-name concert-backend-template \
  --version-description "Concert backend with Docker" \
  --launch-template-data "{
    \"ImageId\": \"$IMAGE_ID\",
    \"InstanceType\": \"$INSTANCE_TYPE\",
    \"SecurityGroupIds\": [\"$(echo $SECURITY_GROUPS | tr ',' '\",\"')\"],
    \"IamInstanceProfile\": {
      \"Name\": \"concert-ec2-role\"
    },
    \"UserData\": \"$(echo '#!/bin/bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:cors-fix
docker run -d -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306/concert_db \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=REDACTED_PASSWORD_C \
  -e AWS_REGION=us-east-1 \
  --restart unless-stopped \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:cors-fix' | base64)\"
  }" \
  --query 'LaunchTemplate.LaunchTemplateId' \
  --output text 2>/dev/null || aws ec2 describe-launch-templates --region $REGION --launch-template-names concert-backend-template --query 'LaunchTemplates[0].LaunchTemplateId' --output text)

echo "✅ Launch Template: $LAUNCH_TEMPLATE"

# Create Target Group
echo "🎯 Creating Target Group..."
TG_ARN=$(aws elbv2 create-target-group \
  --region $REGION \
  --name concert-backend-asg-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --health-check-path /api/auth/test \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || aws elbv2 describe-target-groups --region $REGION --names concert-backend-asg-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "✅ Target Group: $TG_ARN"

# Create Auto Scaling Group
echo "⚙️  Creating Auto Scaling Group..."
aws autoscaling create-auto-scaling-group \
  --region $REGION \
  --auto-scaling-group-name concert-backend-asg \
  --launch-template "LaunchTemplateId=$LAUNCH_TEMPLATE,Version=\$Latest" \
  --min-size 1 \
  --max-size 3 \
  --desired-capacity 1 \
  --vpc-zone-identifier "$SUBNET_IDS" \
  --target-group-arns "$TG_ARN" \
  --health-check-type ELB \
  --health-check-grace-period 300 \
  --tags "Key=Name,Value=concert-backend-asg,PropagateAtLaunch=true" 2>/dev/null || echo "ASG already exists"

# Create Scaling Policies
echo "📊 Creating Scaling Policies..."

# Scale Up Policy
SCALE_UP_POLICY=$(aws autoscaling put-scaling-policy \
  --region $REGION \
  --auto-scaling-group-name concert-backend-asg \
  --policy-name concert-scale-up \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration "{
    \"PredefinedMetricSpecification\": {
      \"PredefinedMetricType\": \"ASGAverageCPUUtilization\"
    },
    \"TargetValue\": 70.0
  }" \
  --query 'PolicyARN' \
  --output text 2>/dev/null || echo "Policy exists")

echo "✅ Scale Up Policy: $SCALE_UP_POLICY"

echo ""
echo "✅ Auto Scaling Setup Complete!"
echo ""
echo "📊 Configuration:"
echo "  Min Instances: 1"
echo "  Max Instances: 3"
echo "  Desired: 1"
echo "  Scale Up: CPU > 70%"
echo ""
echo "🔍 Check status:"
echo "  aws autoscaling describe-auto-scaling-groups --region $REGION --auto-scaling-group-names concert-backend-asg"
