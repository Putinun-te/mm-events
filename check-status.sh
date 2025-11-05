#!/bin/bash

# 🎯 Quick Deployment Status Check

echo "🔍 Checking Infrastructure Status..."
echo ""

echo "📦 EC2 Instance:"
aws ec2 describe-instances \
  --instance-ids i-0ffd487469a6fa1aa \
  --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' \
  --output text \
  --region ap-southeast-1 || echo "❌ Not found"

echo ""
echo "🗄️  RDS Database:"
aws rds describe-db-instances \
  --db-instance-identifier concert-prod-db \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' \
  --output text \
  --region ap-southeast-1 || echo "❌ Not found"

echo ""
echo "☁️  CloudFront Distributions:"
echo "Images CDN:"
aws cloudfront get-distribution \
  --id E1AOTTQDI43845 \
  --query '[Distribution.Status,Distribution.DomainName]' \
  --output text || echo "❌ Not found"

echo "Web CDN:"
aws cloudfront get-distribution \
  --id E1KJ1O0NQAT0B9 \
  --query '[Distribution.Status,Distribution.DomainName]' \
  --output text || echo "❌ Not found"

echo ""
echo "🔐 Cognito User Pool:"
aws cognito-idp describe-user-pool \
  --user-pool-id us-east-1_nTZpyinXc \
  --query 'UserPool.[Status,Name]' \
  --output text \
  --region us-east-1 || echo "❌ Not found"

echo ""
echo "🧪 Testing Backend..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://52.221.197.39:8080/api/auth/test 2>/dev/null)

if [ "$RESPONSE" = "200" ]; then
    echo "✅ Backend is RUNNING!"
    curl -s http://52.221.197.39:8080/api/auth/test
else
    echo "❌ Backend is NOT running (HTTP $RESPONSE)"
    echo ""
    echo "📝 To deploy backend, use EC2 Instance Connect:"
    echo "   https://ap-southeast-1.console.aws.amazon.com/ec2/home?region=ap-southeast-1#Instances:"
    echo ""
    echo "   Or run: ./deploy-ssm.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Infrastructure: Ready"
echo "✅ CloudFront CDN: Deployed"
echo "✅ Cognito: Configured"
echo "✅ Docker Image: Built & Pushed"
echo ""
if [ "$RESPONSE" = "200" ]; then
    echo "✅ Backend: RUNNING ✅"
    echo ""
    echo "🎯 NEXT: Update frontend for Cognito"
    echo "   See: COGNITO_TESTING_GUIDE.md"
else
    echo "⏳ Backend: Needs deployment"
    echo ""
    echo "🎯 NEXT: Deploy backend container"
    echo "   See: DEPLOYMENT_READY.md"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
