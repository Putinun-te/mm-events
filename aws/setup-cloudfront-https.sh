#!/bin/bash

set -e

BUCKET_NAME="concert-frontend-1763745483"
REGION="ap-southeast-1"

echo "☁️ Setting up CloudFront with HTTPS for S3 bucket: $BUCKET_NAME"

# Create CloudFront distribution
cat > /tmp/cf-dist.json <<EOF
{
  "CallerReference": "$(date +%s)",
  "Comment": "Concert Frontend HTTPS",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "S3-$BUCKET_NAME",
      "DomainName": "$BUCKET_NAME.s3.$REGION.amazonaws.com",
      "S3OriginConfig": {
        "OriginAccessIdentity": ""
      }
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET_NAME",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"}
    },
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [{
      "ErrorCode": 404,
      "ResponsePagePath": "/index.html",
      "ResponseCode": "200",
      "ErrorCachingMinTTL": 300
    }]
  },
  "Enabled": true
}
EOF

echo "📦 Creating CloudFront distribution..."
DIST_OUTPUT=$(aws cloudfront create-distribution --distribution-config file:///tmp/cf-dist.json)

DIST_ID=$(echo $DIST_OUTPUT | jq -r '.Distribution.Id')
DIST_DOMAIN=$(echo $DIST_OUTPUT | jq -r '.Distribution.DomainName')

echo "✅ CloudFront created!"
echo ""
echo "🌐 HTTPS URL: https://$DIST_DOMAIN"
echo "📋 Distribution ID: $DIST_ID"
echo ""
echo "⏳ Wait 15-20 minutes for deployment to complete"
echo ""
echo "📊 Check status:"
echo "aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.Status'"
echo ""
echo "💾 Save this info:"
echo "  Distribution ID: $DIST_ID"
echo "  URL: https://$DIST_DOMAIN"

rm /tmp/cf-dist.json
