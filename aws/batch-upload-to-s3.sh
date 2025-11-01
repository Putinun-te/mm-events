#!/bin/bash

################################################################################
# S3 Batch Upload Script
# Upload multiple files or entire directories to S3
# Usage: ./batch-upload-to-s3.sh <source> <bucket-type> [destination-folder]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Bucket names
EVENT_BUCKET="concert-event-pictures-useast1-123456789012"
AVATAR_BUCKET="concert-user-avatars-useast1-123456789012"

usage() {
    echo -e "${YELLOW}Usage: $0 <source> <bucket-type> [destination-folder]${NC}"
    echo ""
    echo "Source: File, directory, or wildcard pattern"
    echo "Bucket types: events, avatars"
    echo ""
    echo "Examples:"
    echo "  $0 images/ events event-photos"
    echo "  $0 *.jpg avatars profile-pics"
    echo "  $0 /path/to/folder events uploads/2025"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

SOURCE="$1"
BUCKET_TYPE="$2"
DEST_FOLDER="${3:-batch-$(date +%Y%m%d-%H%M%S)}"

# Select bucket
case "$BUCKET_TYPE" in
    events)
        BUCKET="$EVENT_BUCKET"
        ;;
    avatars)
        BUCKET="$AVATAR_BUCKET"
        ;;
    *)
        echo -e "${RED}Error: Invalid bucket type${NC}"
        usage
        ;;
esac

echo -e "${BLUE}=== S3 Batch Upload ===${NC}"
echo "Source: $SOURCE"
echo "Bucket: s3://$BUCKET"
echo "Destination: $DEST_FOLDER"
echo ""

# Upload with progress
if [ -d "$SOURCE" ]; then
    # Directory upload
    echo -e "${YELLOW}Uploading directory...${NC}"
    aws s3 cp "$SOURCE" "s3://${BUCKET}/${DEST_FOLDER}/" --recursive
elif [[ "$SOURCE" == *"*"* ]]; then
    # Wildcard pattern
    echo -e "${YELLOW}Uploading files matching pattern...${NC}"
    for file in $SOURCE; do
        if [ -f "$file" ]; then
            echo "  Uploading: $file"
            aws s3 cp "$file" "s3://${BUCKET}/${DEST_FOLDER}/$(basename "$file")"
        fi
    done
else
    # Single file
    echo -e "${YELLOW}Uploading single file...${NC}"
    aws s3 cp "$SOURCE" "s3://${BUCKET}/${DEST_FOLDER}/$(basename "$SOURCE")"
fi

echo ""
echo -e "${GREEN}✓ Upload completed!${NC}"
echo ""

# Show uploaded files
echo -e "${YELLOW}Uploaded files:${NC}"
aws s3 ls "s3://${BUCKET}/${DEST_FOLDER}/" --recursive

# Calculate total size
echo ""
echo -e "${YELLOW}Storage summary:${NC}"
TOTAL_SIZE=$(aws s3 ls "s3://${BUCKET}/${DEST_FOLDER}/" --recursive --summarize | grep "Total Size" | awk '{print $3}')
TOTAL_OBJECTS=$(aws s3 ls "s3://${BUCKET}/${DEST_FOLDER}/" --recursive --summarize | grep "Total Objects" | awk '{print $3}')

if [ ! -z "$TOTAL_SIZE" ]; then
    SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1048576" | bc)
    echo "Total Objects: $TOTAL_OBJECTS"
    echo "Total Size: ${SIZE_MB} MB"
fi
