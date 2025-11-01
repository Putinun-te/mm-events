#!/bin/bash

# ============================================================================
# FRONTEND DEPLOYMENT SCRIPT - Deploy to S3 + CloudFront
# ============================================================================
# Purpose: Build and deploy frontend application to S3 with CloudFront invalidation
# Usage: ./deploy-frontend-to-s3.sh [environment]
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
FRONTEND_DIR="../main_frontend/concert1"
BUILD_DIR="${FRONTEND_DIR}/.output/public"
S3_BUCKET="concert-dev-frontend-d453b7db"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Frontend Deployment to S3 + CloudFront${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Environment:${NC} $ENVIRONMENT"
echo -e "${YELLOW}Frontend Dir:${NC} $FRONTEND_DIR"
echo -e "${YELLOW}S3 Bucket:${NC} $S3_BUCKET"
echo ""

# ============================================================================
# Step 1: Check if frontend directory exists
# ============================================================================
if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}✗ Frontend directory not found: $FRONTEND_DIR${NC}"
    exit 1
fi

cd "$FRONTEND_DIR"
echo -e "${GREEN}✓ Found frontend directory${NC}"

# ============================================================================
# Step 2: Install dependencies
# ============================================================================
echo ""
echo -e "${BLUE}Installing dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    npm install
else
    echo -e "${GREEN}✓ Dependencies already installed${NC}"
fi

# ============================================================================
# Step 3: Build frontend application
# ============================================================================
echo ""
echo -e "${BLUE}Building frontend application...${NC}"
npm run generate  # For Nuxt static site generation

if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}✗ Build failed - output directory not found: $BUILD_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build completed successfully${NC}"

# ============================================================================
# Step 4: Sync files to S3
# ============================================================================
echo ""
echo -e "${BLUE}Uploading files to S3...${NC}"

# Upload all files to S3 with appropriate cache headers
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" \
    --delete \
    --cache-control "max-age=31536000" \
    --exclude "*.html" \
    --exclude "index.html"

# Upload HTML files with no-cache to ensure updates are immediately visible
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" \
    --delete \
    --cache-control "no-cache, no-store, must-revalidate" \
    --exclude "*" \
    --include "*.html"

echo -e "${GREEN}✓ Files uploaded to S3${NC}"

# ============================================================================
# Step 5: Get CloudFront distribution ID
# ============================================================================
echo ""
echo -e "${BLUE}Getting CloudFront distribution ID...${NC}"

DISTRIBUTION_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Origins.Items[?DomainName=='${S3_BUCKET}.s3.amazonaws.com']].Id | [0]" \
    --output text 2>/dev/null || echo "")

if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" == "None" ]; then
    echo -e "${YELLOW}⚠ CloudFront distribution not found. Skipping invalidation.${NC}"
    echo -e "${YELLOW}  Deploy CloudFront with: terraform apply${NC}"
else
    echo -e "${GREEN}✓ Found CloudFront distribution: $DISTRIBUTION_ID${NC}"
    
    # ============================================================================
    # Step 6: Create CloudFront invalidation
    # ============================================================================
    echo ""
    echo -e "${BLUE}Creating CloudFront invalidation...${NC}"
    
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    echo -e "${GREEN}✓ Invalidation created: $INVALIDATION_ID${NC}"
    echo -e "${YELLOW}  Note: Invalidation may take 5-15 minutes to complete${NC}"
fi

# ============================================================================
# Step 7: Display deployment information
# ============================================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Completed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}S3 Bucket URL:${NC}"
echo -e "  http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com"
echo ""

if [ -n "$DISTRIBUTION_ID" ] && [ "$DISTRIBUTION_ID" != "None" ]; then
    CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
        --id "$DISTRIBUTION_ID" \
        --query 'Distribution.DomainName' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$CLOUDFRONT_DOMAIN" ] && [ "$CLOUDFRONT_DOMAIN" != "None" ]; then
        echo -e "${BLUE}CloudFront URL:${NC}"
        echo -e "  ${GREEN}https://$CLOUDFRONT_DOMAIN${NC}"
        echo ""
    fi
fi

echo -e "${BLUE}Files uploaded:${NC}"
FILE_COUNT=$(aws s3 ls "s3://$S3_BUCKET" --recursive | wc -l | tr -d ' ')
echo -e "  Total: $FILE_COUNT files"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Wait for CloudFront invalidation to complete (5-15 min)"
echo -e "  2. Test your application at the CloudFront URL"
echo -e "  3. Monitor CloudFront metrics in AWS Console"
echo ""
