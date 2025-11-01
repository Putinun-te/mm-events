#!/bin/bash

################################################################################
# S3 Upload Helper Script
# Usage: ./upload-to-s3.sh <file> <bucket-type> [folder]
# 
# Examples:
#   ./upload-to-s3.sh image.jpg events
#   ./upload-to-s3.sh avatar.png avatars public
#   ./upload-to-s3.sh poster.jpg events events/2025
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Bucket names
EVENT_BUCKET="concert-event-pictures-useast1-123456789012"
AVATAR_BUCKET="concert-user-avatars-useast1-123456789012"

# Function to print usage
usage() {
    echo -e "${YELLOW}Usage: $0 <file> <bucket-type> [folder]${NC}"
    echo ""
    echo "Bucket types:"
    echo "  events  - Upload to event pictures bucket"
    echo "  avatars - Upload to user avatars bucket"
    echo ""
    echo "Examples:"
    echo "  $0 image.jpg events"
    echo "  $0 avatar.png avatars"
    echo "  $0 poster.jpg events events/2025"
    echo "  $0 profile.png avatars users/123"
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    usage
fi

FILE="$1"
BUCKET_TYPE="$2"
FOLDER="${3:-uploads}"

# Validate file exists
if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: File '$FILE' not found${NC}"
    exit 1
fi

# Select bucket
case "$BUCKET_TYPE" in
    events)
        BUCKET="$EVENT_BUCKET"
        ;;
    avatars)
        BUCKET="$AVATAR_BUCKET"
        ;;
    *)
        echo -e "${RED}Error: Invalid bucket type '$BUCKET_TYPE'${NC}"
        usage
        ;;
esac

# Get file info
FILENAME=$(basename "$FILE")
FILESIZE=$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE" 2>/dev/null)
FILESIZE_MB=$(echo "scale=2; $FILESIZE / 1048576" | bc)

# Generate unique filename
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
UNIQUE_FILENAME="${TIMESTAMP}-${FILENAME}"
S3_KEY="${FOLDER}/${UNIQUE_FILENAME}"

echo -e "${YELLOW}=== S3 Upload ===${NC}"
echo "File: $FILE"
echo "Size: ${FILESIZE_MB} MB"
echo "Bucket: s3://$BUCKET"
echo "Key: $S3_KEY"
echo ""

# Upload file
echo -e "${YELLOW}Uploading...${NC}"
if aws s3 cp "$FILE" "s3://${BUCKET}/${S3_KEY}"; then
    echo -e "${GREEN}✓ Upload successful!${NC}"
    echo ""
    echo "S3 URI: s3://${BUCKET}/${S3_KEY}"
    echo "URL: https://${BUCKET}.s3.amazonaws.com/${S3_KEY}"
    echo ""
    
    # Generate presigned URL (valid for 1 hour)
    echo -e "${YELLOW}Generating presigned URL (valid for 1 hour)...${NC}"
    PRESIGNED_URL=$(aws s3 presign "s3://${BUCKET}/${S3_KEY}" --expires-in 3600)
    echo "Presigned URL: $PRESIGNED_URL"
    echo ""
    
    # Show object metadata
    echo -e "${YELLOW}Object metadata:${NC}"
    aws s3api head-object --bucket "$BUCKET" --key "$S3_KEY" | jq '{
        ContentType: .ContentType,
        ContentLength: .ContentLength,
        LastModified: .LastModified,
        ETag: .ETag,
        StorageClass: .StorageClass
    }'
else
    echo -e "${RED}✗ Upload failed${NC}"
    exit 1
fi
