#!/bin/bash

set -e

BUCKET_NAME="concert-frontend-1763745483"
FRONTEND_DIR="../main_frontend/concert1"

echo "📦 Deploying to existing S3 bucket: $BUCKET_NAME"

# Build frontend
echo "🔨 Building frontend..."
cd $FRONTEND_DIR
npm run build
cd -

# Upload to existing bucket
echo "⬆️  Uploading to S3..."
aws s3 sync $FRONTEND_DIR/.output/public s3://$BUCKET_NAME --delete

echo "✅ Deployed!"
echo ""
echo "🌐 Access via:"
echo "  S3: http://$BUCKET_NAME.s3-website-ap-southeast-1.amazonaws.com"
echo ""
echo "💡 To enable public access:"
echo "  1. Go to S3 Console → $BUCKET_NAME"
echo "  2. Permissions → Block Public Access → Edit → Uncheck all"
echo "  3. Bucket Policy → Add:"
echo '  {
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::'$BUCKET_NAME'/*"
    }]
  }'
