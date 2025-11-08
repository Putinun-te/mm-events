#!/bin/bash
set -e

# Setup HTTPS backend with ALB
REGION="ap-southeast-1"
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=concert-prod-vpc" --query 'Vpcs[0].VpcId' --output text)
INSTANCE_ID="i-0ffd487469a6fa1aa"

echo "🔍 Found VPC: $VPC_ID"

# Get subnets
SUBNET_IDS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" --query 'Subnets[*].SubnetId' --output text | tr '\t' ' ')
echo "🔍 Found Subnets: $SUBNET_IDS"

# Create security group for ALB
echo "🔒 Creating ALB security group..."
ALB_SG_ID=$(aws ec2 create-security-group \
  --region $REGION \
  --group-name concert-alb-sg \
  --description "Security group for Concert ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text 2>/dev/null || aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=concert-alb-sg" --query 'SecurityGroups[0].GroupId' --output text)

echo "🔍 ALB Security Group: $ALB_SG_ID"

# Allow HTTP and HTTPS
aws ec2 authorize-security-group-ingress --region $REGION --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $ALB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 2>/dev/null || true

# Create ALB
echo "🚀 Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
  --region $REGION \
  --name concert-backend-alb \
  --subnets $SUBNET_IDS \
  --security-groups $ALB_SG_ID \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || aws elbv2 describe-load-balancers --region $REGION --names concert-backend-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "✅ ALB ARN: $ALB_ARN"

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers --region $REGION --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)
echo "🌐 ALB DNS: $ALB_DNS"

# Create target group
echo "🎯 Creating target group..."
TG_ARN=$(aws elbv2 create-target-group \
  --region $REGION \
  --name concert-backend-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --health-check-path /api/auth/test \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || aws elbv2 describe-target-groups --region $REGION --names concert-backend-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "✅ Target Group ARN: $TG_ARN"

# Register EC2 instance
echo "📝 Registering EC2 instance..."
aws elbv2 register-targets \
  --region $REGION \
  --target-group-arn $TG_ARN \
  --targets Id=$INSTANCE_ID

# Create HTTP listener (redirect to HTTPS later)
echo "👂 Creating HTTP listener..."
aws elbv2 create-listener \
  --region $REGION \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN 2>/dev/null || echo "Listener already exists"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📊 Backend URLs:"
echo "  HTTP: http://$ALB_DNS"
echo "  Test: http://$ALB_DNS/api/auth/test"
echo ""
echo "⚠️  For HTTPS, you need to:"
echo "  1. Request an SSL certificate in ACM"
echo "  2. Add HTTPS listener to ALB"
echo "  3. Update frontend BACKEND_BASE_URL to use ALB DNS"
echo ""
echo "🔧 Update frontend .env:"
echo "  BACKEND_BASE_URL=http://$ALB_DNS"