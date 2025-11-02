#!/bin/bash

##############################################################################
# Concert Platform v1.0.0 Release Script
# 
# This script automates the deployment process for the Concert Platform
# 
# Usage:
#   ./release.sh [--dry-run] [--skip-tests] [--skip-backup]
#
# Options:
#   --dry-run      Show what would be done without making changes
#   --skip-tests   Skip running tests (not recommended)
#   --skip-backup  Skip database backup (not recommended)
##############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="1.0.0"
RELEASE_BRANCH="release/v${VERSION}"
DRY_RUN=false
SKIP_TESTS=false
SKIP_BACKUP=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --skip-backup)
      SKIP_BACKUP=true
      shift
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--dry-run] [--skip-tests] [--skip-backup]"
      exit 1
      ;;
  esac
done

##############################################################################
# Helper Functions
##############################################################################

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
  if [ "$DRY_RUN" = true ]; then
    return 0
  fi
  
  read -p "$(echo -e ${YELLOW}$1${NC}) [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Aborted by user"
    exit 1
  fi
}

run_command() {
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would execute: $1"
  else
    log_info "Executing: $1"
    eval "$1"
  fi
}

##############################################################################
# Pre-flight Checks
##############################################################################

log_info "Starting Concert Platform v${VERSION} release process"
echo "=================================================="

# Check if on correct branch
CURRENT_BRANCH=$(git branch --show-current)
log_info "Current branch: $CURRENT_BRANCH"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  log_warning "You have uncommitted changes!"
  git status --short
  confirm "Continue anyway?"
fi

# Check required tools
log_info "Checking required tools..."
command -v java >/dev/null 2>&1 || { log_error "Java is not installed"; exit 1; }
command -v mvn >/dev/null 2>&1 || { log_error "Maven is not installed"; exit 1; }
command -v node >/dev/null 2>&1 || { log_error "Node.js is not installed"; exit 1; }
command -v npm >/dev/null 2>&1 || { log_error "npm is not installed"; exit 1; }
command -v terraform >/dev/null 2>&1 || { log_error "Terraform is not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { log_error "AWS CLI is not installed"; exit 1; }

log_success "All required tools are installed"

##############################################################################
# Phase 1: Code Preparation
##############################################################################

log_info "Phase 1: Code Preparation"
echo "=================================================="

# Create release branch if it doesn't exist
if ! git rev-parse --verify "$RELEASE_BRANCH" >/dev/null 2>&1; then
  confirm "Create release branch $RELEASE_BRANCH?"
  run_command "git checkout -b $RELEASE_BRANCH"
else
  log_info "Release branch already exists"
  confirm "Checkout $RELEASE_BRANCH?"
  run_command "git checkout $RELEASE_BRANCH"
fi

# Update version in pom.xml
log_info "Updating backend version to $VERSION"
if [ "$DRY_RUN" = false ]; then
  sed -i '' "s|<version>.*</version>|<version>${VERSION}</version>|" main_backend/pom.xml || true
fi

# Update version in package.json
log_info "Updating frontend version to $VERSION"
if [ "$DRY_RUN" = false ]; then
  cd main_frontend/concert1
  npm version "$VERSION" --no-git-tag-version || true
  cd ../..
fi

log_success "Version updated to $VERSION"

##############################################################################
# Phase 2: Testing
##############################################################################

if [ "$SKIP_TESTS" = false ]; then
  log_info "Phase 2: Testing"
  echo "=================================================="

  # Backend tests
  log_info "Running backend tests..."
  cd main_backend
  run_command "JAVA_HOME=\$(/usr/libexec/java_home -v 21) mvn clean test"
  log_success "Backend tests passed"
  cd ..

  # Frontend tests
  log_info "Running frontend tests..."
  cd main_frontend/concert1
  run_command "npm run test"
  log_success "Frontend tests passed"
  cd ../..
else
  log_warning "Skipping tests as requested"
fi

##############################################################################
# Phase 3: Database Backup
##############################################################################

if [ "$SKIP_BACKUP" = false ]; then
  log_info "Phase 3: Database Backup"
  echo "=================================================="

  confirm "Create RDS snapshot before deployment?"
  
  DB_INSTANCE="concert-db-dev"
  SNAPSHOT_ID="concert-db-pre-release-v${VERSION}-$(date +%Y%m%d-%H%M%S)"
  
  log_info "Creating RDS snapshot: $SNAPSHOT_ID"
  run_command "aws rds create-db-snapshot \
    --db-instance-identifier $DB_INSTANCE \
    --db-snapshot-identifier $SNAPSHOT_ID"
  
  if [ "$DRY_RUN" = false ]; then
    log_info "Waiting for snapshot to complete..."
    aws rds wait db-snapshot-completed --db-snapshot-identifier "$SNAPSHOT_ID"
  fi
  
  log_success "Database snapshot created: $SNAPSHOT_ID"
else
  log_warning "Skipping database backup as requested"
fi

##############################################################################
# Phase 4: Build Backend
##############################################################################

log_info "Phase 4: Build Backend"
echo "=================================================="

cd main_backend

log_info "Building backend JAR..."
run_command "mvn clean package -DskipTests"

if [ "$DRY_RUN" = false ]; then
  JAR_FILE=$(ls target/*.jar | grep -v original)
  log_success "Backend built: $JAR_FILE"
  log_info "JAR size: $(du -h "$JAR_FILE" | cut -f1)"
fi

cd ..

##############################################################################
# Phase 5: Build Frontend
##############################################################################

log_info "Phase 5: Build Frontend"
echo "=================================================="

cd main_frontend/concert1

# Check if .env.production exists
if [ ! -f .env.production ]; then
  log_warning ".env.production not found!"
  log_info "Please create it with the following variables:"
  echo "  NUXT_PUBLIC_API_BASE_URL=<api-gateway-url>"
  echo "  NUXT_PUBLIC_COGNITO_USER_POOL_ID=<pool-id>"
  echo "  NUXT_PUBLIC_COGNITO_CLIENT_ID=<client-id>"
  echo "  NUXT_PUBLIC_COGNITO_REGION=us-east-1"
  confirm "Continue without .env.production?"
fi

log_info "Installing frontend dependencies..."
run_command "npm ci"

log_info "Building frontend..."
run_command "npm run generate"

if [ "$DRY_RUN" = false ]; then
  log_success "Frontend built: .output/public"
  log_info "Build size: $(du -sh .output/public | cut -f1)"
fi

cd ../..

##############################################################################
# Phase 6: Deploy Infrastructure
##############################################################################

log_info "Phase 6: Deploy Infrastructure"
echo "=================================================="

cd aws

confirm "Deploy infrastructure changes with Terraform?"

log_info "Initializing Terraform..."
run_command "terraform init"

log_info "Planning infrastructure changes..."
run_command "terraform plan -out=release.tfplan"

if [ "$DRY_RUN" = false ]; then
  echo ""
  log_warning "Review the Terraform plan above"
  confirm "Apply these infrastructure changes?"
fi

log_info "Applying infrastructure changes..."
run_command "terraform apply release.tfplan"

# Get outputs
if [ "$DRY_RUN" = false ]; then
  API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
  S3_BUCKET=$(terraform output -raw frontend_s3_bucket_name 2>/dev/null || echo "")
  
  if [ -n "$API_URL" ]; then
    log_success "API Gateway URL: $API_URL"
  fi
  if [ -n "$S3_BUCKET" ]; then
    log_success "S3 Bucket: $S3_BUCKET"
  fi
fi

cd ..

##############################################################################
# Phase 7: Deploy Frontend
##############################################################################

log_info "Phase 7: Deploy Frontend to S3"
echo "=================================================="

if [ "$DRY_RUN" = false ]; then
  cd aws
  S3_BUCKET=$(terraform output -raw frontend_s3_bucket_name)
  cd ..
  
  log_info "Deploying to S3 bucket: $S3_BUCKET"
  
  # Sync static assets with long cache
  log_info "Uploading static assets..."
  aws s3 sync main_frontend/concert1/.output/public s3://$S3_BUCKET \
    --delete \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "*.html" \
    --exclude "*.json"
  
  # Sync HTML/JSON with no cache
  log_info "Uploading HTML and JSON files..."
  aws s3 sync main_frontend/concert1/.output/public s3://$S3_BUCKET \
    --delete \
    --cache-control "no-cache, no-store, must-revalidate" \
    --exclude "*" \
    --include "*.html" \
    --include "*.json"
  
  log_success "Frontend deployed to S3"
else
  log_info "[DRY-RUN] Would deploy frontend to S3"
fi

##############################################################################
# Phase 8: Deploy Backend
##############################################################################

log_info "Phase 8: Deploy Backend"
echo "=================================================="

log_warning "Backend deployment requires manual steps or CI/CD"
log_info "Options:"
echo "  1. Push to GitHub to trigger CI/CD pipeline"
echo "  2. Manually SCP JAR to EC2 and restart service"
echo ""
confirm "Skip backend deployment for now?"

##############################################################################
# Phase 9: Verification
##############################################################################

log_info "Phase 9: Verification"
echo "=================================================="

if [ "$DRY_RUN" = false ]; then
  cd aws
  API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
  S3_URL=$(terraform output -raw frontend_s3_website_url 2>/dev/null || echo "")
  cd ..
  
  if [ -n "$API_URL" ]; then
    log_info "Testing API Gateway..."
    
    # Test health endpoint
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/auth/test" || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
      log_success "API is responding (HTTP $HTTP_CODE)"
    else
      log_warning "API returned HTTP $HTTP_CODE"
    fi
  fi
  
  if [ -n "$S3_URL" ]; then
    log_info "Frontend URL: $S3_URL"
    log_info "Opening frontend in browser..."
    open "$S3_URL" 2>/dev/null || true
  fi
fi

##############################################################################
# Phase 10: Git Tagging
##############################################################################

log_info "Phase 10: Git Tagging"
echo "=================================================="

confirm "Commit version changes and create git tag v$VERSION?"

if [ "$DRY_RUN" = false ]; then
  git add main_backend/pom.xml main_frontend/concert1/package.json
  git commit -m "chore: bump version to $VERSION" || true
  git tag -a "v$VERSION" -m "Release v$VERSION - Concert Platform

Features:
- User authentication with Cognito
- Event management (create, list, view)
- Booking system
- Event photo uploads to S3
- API Gateway with rate limiting
- Auto-scaling backend
- CloudWatch monitoring
- CI/CD pipeline with GitHub Actions

See RELEASE_NOTES.md for full details."
  
  log_success "Git tag v$VERSION created"
fi

##############################################################################
# Summary
##############################################################################

echo ""
echo "=================================================="
log_success "Release v$VERSION deployment completed!"
echo "=================================================="
echo ""

log_info "Next Steps:"
echo "  1. Push release branch: git push origin $RELEASE_BRANCH"
echo "  2. Push tag: git push origin v$VERSION"
echo "  3. Create GitHub release with RELEASE_NOTES.md"
echo "  4. Configure GitHub secrets for CI/CD"
echo "  5. Merge to main: git checkout main && git merge $RELEASE_BRANCH"
echo "  6. Monitor CloudWatch for 24 hours"
echo "  7. Update documentation as needed"
echo ""

if [ "$DRY_RUN" = false ]; then
  cd aws
  API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not deployed")
  S3_URL=$(terraform output -raw frontend_s3_website_url 2>/dev/null || echo "Not deployed")
  cd ..
  
  log_info "Deployment URLs:"
  echo "  Frontend: $S3_URL"
  echo "  API:      $API_URL"
  echo ""
fi

log_info "Documentation:"
echo "  - Release Notes: RELEASE_NOTES.md"
echo "  - Release Checklist: RELEASE_CHECKLIST.md"
echo "  - Production Readiness: aws/PRODUCTION_READINESS_CHECKLIST.md"
echo "  - API Gateway Guide: aws/API_GATEWAY_SETUP_GUIDE.md"
echo ""

if [ "$DRY_RUN" = true ]; then
  log_warning "This was a DRY RUN - no changes were made"
  log_info "Run without --dry-run to execute the release"
fi

log_success "Done! 🎉"
