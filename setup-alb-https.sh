#!/bin/bash
set -e

REGION="ap-southeast-1"
INSTANCE_ID="i-0e48bfcfd02bf9c00"

# Get VPC and subnets
VPC_ID=$(aws ec2 describe-instances --region $REGION --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | tr '\t' ' ')

echo "VPC: $VPC_ID"
echo "Subnets: $SUBNET_IDS"

# Create ALB security group
ALB_SG=$(aws ec2 create-security-group \
  --region $REGION \
  --group-name concert-alb-sg \
  --description "ALB for Concert Backend" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text 2>/dev/null || aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=concert-alb-sg" --query 'SecurityGroups[0].GroupId' --output text)

aws ec2 authorize-security-group-ingress --region $REGION --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0 2>/dev/null || true

# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --region $REGION \
  --name concert-alb \
  --subnets $SUBNET_IDS \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || aws elbv2 describe-load-balancers --region $REGION --names concert-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers --region $REGION --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
  --region $REGION \
  --name concert-backend-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --health-check-path /api/auth/test \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || aws elbv2 describe-target-groups --region $REGION --names concert-backend-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# Register instance
aws elbv2 register-targets --region $REGION --target-group-arn $TG_ARN --targets Id=$INSTANCE_ID

# Create HTTP listener
aws elbv2 create-listener \
  --region $REGION \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN 2>/dev/null || echo "Listener exists"

echo ""
echo "✅ ALB Created!"
echo "HTTP URL: http://$ALB_DNS"
echo ""
echo "Update API Gateway to use: http://$ALB_DNS"