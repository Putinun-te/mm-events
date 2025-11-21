#!/bin/bash

set -e

REGION="ap-southeast-1"
BUCKET_NAME="concert-frontend-$(date +%s)"
FRONTEND_DIR="../main_frontend/concert1"

echo "🚀 Deploying Frontend to S3 + CloudFront..."

# Build frontend
echo "📦 Building frontend..."
cd $FRONTEND_DIR
npm run build
cd -

# Create S3 bucket
echo "🪣 Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document index.html

# Upload files
echo "⬆️  Uploading files..."
aws s3 sync $FRONTEND_DIR/.output/public s3://$BUCKET_NAME --delete

# Create CloudFront Origin Access Identity
echo "🔐 Creating CloudFront OAI..."
OAI_ID=$(aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
  CallerReference=$(date +%s),Comment="Concert Frontend OAI" \
  --query 'CloudFrontOriginAccessIdentity.Id' \
  --output text)

# Update bucket policy for CloudFront OAI only
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Sid\": \"CloudFrontAccess\",
    \"Effect\": \"Allow\",
    \"Principal\": {\"AWS\": \"arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity $OAI_ID\"},
    \"Action\": \"s3:GetObject\",
    \"Resource\": \"arn:aws:s3:::$BUCKET_NAME/*\"
  }]
}"

# Create CloudFront distribution config
cat > /tmp/cf-config.json <<EOF
{
  "CallerReference": "$(date +%s)",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "S3-$BUCKET_NAME",
      "DomainName": "$BUCKET_NAME.s3.$REGION.amazonaws.com",
      "S3OriginConfig": {
        "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
      }
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET_NAME",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {"Quantity": 2, "Items": ["GET", "HEAD"]},
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"}
    },
    "MinTTL": 0,
    "Compress": true
  },
  "Comment": "Concert Frontend",
  "Enabled": true
}
EOF

echo "☁️  Creating CloudFront distribution..."
DIST_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cf-config.json \
  --query 'Distribution.Id' \
  --output text)

DIST_DOMAIN=$(aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.DomainName' --output text)

echo "✅ Deployment complete!"
echo ""
echo "📋 CloudFront URL: https://$DIST_DOMAIN"
echo "⏳ Wait 15 minutes for CloudFront deployment"
echo ""
echo "💾 Save these:"
echo "  Bucket: $BUCKET_NAME"
echo "  Distribution ID: $DIST_ID"
