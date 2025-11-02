#!/bin/bash

# Concert Platform - Deploy Frontend to S3
# This script builds and deploys the Nuxt frontend to S3

set -e

REGION="us-east-1"
S3_BUCKET="concert-dev-frontend-142fee22"
BASE_PATH=""  # Deploy to root, not /concert/

echo "🎨 Concert Platform Frontend Deployment"
echo "========================================"

cd main_frontend/concert1

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found"
    echo "   Creating .env with EC2 backend URL..."
    cat > .env <<EOF
# Backend API Configuration
BACKEND_BASE_URL=http://52.203.64.85:8080
EOF
fi

echo "✅ Environment configured:"
cat .env

# Install dependencies
echo ""
echo "📦 Step 1: Install dependencies..."
npm install

# Build frontend
echo ""
echo "🔨 Step 2: Build frontend..."
npm run generate

# Sync to S3
echo ""
echo "☁️  Step 3: Deploy to S3..."
aws s3 sync .output/public/ \
    "s3://$S3_BUCKET/" \
    --region $REGION \
    --delete \
    --cache-control "public, max-age=3600"

echo ""
echo "✅ Deployment Complete!"
echo "======================================="
echo "Frontend URL: http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com/"
echo ""
echo "Test in browser:"
echo "http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com/"
echo ""
echo "Or use Cognito login URL:"
cd ../../aws
terraform output cognito_login_url
