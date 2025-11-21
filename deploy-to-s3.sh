#!/bin/bash

set -e

BUCKET_NAME="${S3_BUCKET_NAME:-mm-concerts-web}"
REGION="${AWS_REGION:-us-east-1}"
FRONTEND_DIR="main_frontend/concert1"

echo "🚀 Building Nuxt application..."
cd "$FRONTEND_DIR"
npm install
npm run generate

echo "📦 Uploading to S3 bucket: $BUCKET_NAME"
aws s3 sync .output/public/ s3://$BUCKET_NAME/ --delete --region $REGION

echo "🔧 Setting bucket for static website hosting..."
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document index.html --region $REGION

echo "✅ Deployment complete!"
echo "🌐 Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
