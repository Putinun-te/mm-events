#!/bin/bash
# Script to upload image to S3 and get CloudFront URL

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <image-file> <event-id>"
    exit 1
fi

IMAGE_FILE=$1
EVENT_ID=$2
FILENAME=$(basename "$IMAGE_FILE")
S3_KEY="events/${EVENT_ID}/${FILENAME}"
S3_BUCKET="concert-event-pictures-singapore-123456789012"
CLOUDFRONT_URL="https://dzh397ixo71bk.cloudfront.net"

# Upload to S3
aws s3 cp "$IMAGE_FILE" "s3://${S3_BUCKET}/${S3_KEY}" --content-type "image/jpeg"

# Return CloudFront URL
echo "${CLOUDFRONT_URL}/${S3_KEY}"
