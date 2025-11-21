#!/bin/bash

set -e

echo "🧹 Cleaning up new S3 buckets and using old ones..."

# Delete new buckets (empty them first)
echo "Deleting concert-frontend-1763745483..."
aws s3 rm s3://concert-frontend-1763745483 --recursive 2>/dev/null || true
aws s3 rb s3://concert-frontend-1763745483 2>/dev/null || true

echo "Deleting concert-frontend-1763745547..."
aws s3 rm s3://concert-frontend-1763745547 --recursive 2>/dev/null || true
aws s3 rb s3://concert-frontend-1763745547 2>/dev/null || true

echo "✅ New buckets deleted!"
echo ""
echo "📦 Using existing buckets:"
echo "  - concert-web-singapore-123456789012 (Frontend)"
echo "  - concert-event-pictures-singapore-123456789012 (Event images)"
echo "  - concert-user-avatars-singapore-123456789012 (User avatars)"
echo ""

# Deploy frontend to old bucket
BUCKET_NAME="concert-web-singapore-123456789012"
FRONTEND_DIR="../main_frontend/concert1"

echo "🔨 Building frontend..."
cd $FRONTEND_DIR
npm run build
cd -

echo "⬆️  Uploading to $BUCKET_NAME..."
aws s3 sync $FRONTEND_DIR/.output/public s3://$BUCKET_NAME --delete

echo "✅ Frontend deployed to old bucket!"
echo ""
echo "🌐 S3 URL: http://$BUCKET_NAME.s3-website-ap-southeast-1.amazonaws.com"
echo ""
echo "☁️ Now setup CloudFront for HTTPS..."
