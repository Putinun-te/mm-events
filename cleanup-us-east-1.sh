#!/bin/bash
# Clean up US-EAST-1 resources

echo "🧹 Cleaning US-EAST-1..."

# Disable CloudFront distributions
for dist_id in E1AOTTQDI43845 E1KJ1O0NQAT0B9; do
  echo "Disabling CloudFront: $dist_id"
  aws cloudfront get-distribution-config --id $dist_id --query 'DistributionConfig' > /tmp/dist-config.json
  jq '.Enabled = false' /tmp/dist-config.json > /tmp/dist-config-disabled.json
  ETAG=$(aws cloudfront get-distribution-config --id $dist_id --query 'ETag' --output text)
  aws cloudfront update-distribution --id $dist_id --distribution-config file:///tmp/dist-config-disabled.json --if-match $ETAG 2>/dev/null || echo "Already disabled"
done

echo "⚠️  CloudFront distributions disabled. Wait 15 mins then delete manually"
echo ""
echo "To delete S3 buckets:"
echo "  aws s3 rb s3://concert-event-pictures-useast1-123456789012 --force"
echo "  aws s3 rb s3://concert-prod-web-123456789012 --force"
echo "  aws s3 rb s3://concert-user-avatars-useast1-123456789012 --force"
echo ""
echo "✅ Singapore-only setup:"
echo "  Backend: http://concert-alb-1280136752.ap-southeast-1.elb.amazonaws.com"
echo "  EC2: 13.250.108.116"
echo "  RDS: concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com"
