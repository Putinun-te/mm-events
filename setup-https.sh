#!/bin/bash
set -e

REGION="ap-southeast-1"
EC2_INSTANCE="i-0d8e8500cc1ac477c"
VPC_ID="vpc-0f4607ec53e2424b1"

echo "🔒 Setting up HTTPS for backend..."

# Get subnets
SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')
echo "Subnets: $SUBNETS"

# Create ALB security group
ALB_SG=$(aws ec2 create-security-group \
  --region $REGION \
  --group-name concert-alb-sg \
  --description "ALB security group" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text 2>/dev/null || aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=concert-alb-sg" --query 'SecurityGroups[0].GroupId' --output text)

aws ec2 authorize-security-group-ingress --region $REGION --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0 2>/dev/null || true

echo "ALB SG: $ALB_SG"

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
  --region $REGION \
  --name concert-backend-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --health-check-path /actuator/health \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || aws elbv2 describe-target-groups --region $REGION --names concert-backend-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Target Group: $TG_ARN"

# Register EC2
aws elbv2 register-targets --region $REGION --target-group-arn $TG_ARN --targets Id=$EC2_INSTANCE

# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --region $REGION \
  --name concert-alb \
  --subnets $(echo $SUBNETS | tr ',' ' ') \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || aws elbv2 describe-load-balancers --region $REGION --names concert-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB: $ALB_ARN"

# Create HTTP listener (redirect to HTTPS later)
aws elbv2 create-listener \
  --region $REGION \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN 2>/dev/null || echo "Listener exists"

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers --region $REGION --names concert-alb --query 'LoadBalancers[0].DNSName' --output text)

echo ""
echo "✅ HTTP setup complete!"
echo "URL: http://$ALB_DNS"
echo ""
echo "For HTTPS:"
echo "1. Get domain (e.g., Route53)"
echo "2. Request certificate in ACM"
echo "3. Add HTTPS listener with certificate"
