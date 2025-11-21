#!/bin/bash

echo "🔧 Fixing S3 and CloudFront configuration..."

BUCKET_NAME="concert-event-pictures-singapore-123456789012"

# 1. Create S3 bucket if it doesn't exist
echo "Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region ap-southeast-1 2>/dev/null || echo "Bucket already exists"

# 2. Set bucket policy for public read access
echo "Setting S3 bucket policy..."
cat > /tmp/bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file:///tmp/bucket-policy.json

# 3. Enable public access
echo "Configuring public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# 4. Set CORS policy
echo "Setting CORS policy..."
cat > /tmp/cors-policy.json << EOF
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}
EOF

aws s3api put-bucket-cors --bucket $BUCKET_NAME --cors-configuration file:///tmp/cors-policy.json

# 5. Test upload
echo "Testing S3 upload..."
echo "test" > /tmp/test-upload.txt
aws s3 cp /tmp/test-upload.txt s3://$BUCKET_NAME/test/test-upload.txt

# 6. Check if CloudFront distribution exists
echo "Checking CloudFront distribution..."
DISTRIBUTION_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[0].DomainName=='$BUCKET_NAME.s3.ap-southeast-1.amazonaws.com'].Id" --output text)

if [ -n "$DISTRIBUTION_ID" ]; then
  echo "CloudFront distribution found: $DISTRIBUTION_ID"
  CLOUDFRONT_URL=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query "Distribution.DomainName" --output text)
  echo "CloudFront URL: https://$CLOUDFRONT_URL"
else
  echo "No CloudFront distribution found for this bucket"
fi

# Cleanup
rm -f /tmp/bucket-policy.json /tmp/cors-policy.json /tmp/test-upload.txt

echo "✅ S3 and CloudFront configuration completed!"
echo "S3 URL: https://$BUCKET_NAME.s3.ap-southeast-1.amazonaws.com"