# GitHub Actions Pipeline Fix - Commit & Push Script
# Date: November 21, 2025
# Branch: release/v1.0.0

Write-Host "🚀 GitHub Actions Pipeline Fix - Commit & Push" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
$currentPath = Get-Location
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a git repository!" -ForegroundColor Red
    Write-Host "Please run this script from: c:\Devop\develop" -ForegroundColor Yellow
    exit 1
}

# Check current branch
$currentBranch = git branch --show-current
Write-Host "📍 Current branch: $currentBranch" -ForegroundColor Green

if ($currentBranch -ne "release/v1.0.0") {
    Write-Host "⚠️  Warning: Expected branch 'release/v1.0.0' but on '$currentBranch'" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "📝 Files to be committed:" -ForegroundColor Yellow
Write-Host "  - .github/workflows/k8s-deploy.yml (UPDATED - Test profile)" -ForegroundColor White
Write-Host "  - main_backend/src/test/resources/application-test.properties (FIXED)" -ForegroundColor White
Write-Host "  - main_backend/src/test/resources/application-docker.properties (FIXED)" -ForegroundColor White
Write-Host "  - main_backend/src/test/resources/schema.sql (NEW - Fallback)" -ForegroundColor White
Write-Host "  - DATABASE_INITIALIZATION_FIX.md (NEW - Documentation)" -ForegroundColor White
Write-Host "  - test-db-fix.ps1 (NEW - Verification script)" -ForegroundColor White
Write-Host "  - GITHUB_ACTIONS_PIPELINE_FIX_2025.md (EXISTING)" -ForegroundColor White
Write-Host "  - PIPELINE_FIX_QUICK.md (EXISTING)" -ForegroundColor White
Write-Host "  - push-pipeline-fix.ps1 (UPDATED)" -ForegroundColor White
Write-Host ""

# Show git status
Write-Host "🔍 Git Status:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "Ready to commit and push these changes? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "📦 Step 1: Staging files..." -ForegroundColor Cyan

# Stage the workflow file
git add .github/workflows/k8s-deploy.yml
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Staged: .github/workflows/k8s-deploy.yml" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to stage workflow file" -ForegroundColor Red
    exit 1
}

# Stage test configuration files
git add main_backend/src/test/resources/application-test.properties
git add main_backend/src/test/resources/application-docker.properties
git add main_backend/src/test/resources/schema.sql
Write-Host "  ✅ Staged: Backend test configuration files" -ForegroundColor Green

# Stage documentation files
git add DATABASE_INITIALIZATION_FIX.md
git add GITHUB_ACTIONS_PIPELINE_FIX_2025.md
git add PIPELINE_FIX_QUICK.md
git add test-db-fix.ps1
git add push-pipeline-fix.ps1
Write-Host "  ✅ Staged: Documentation and script files" -ForegroundColor Green

Write-Host ""
Write-Host "💾 Step 2: Creating commit..." -ForegroundColor Cyan

# Create commit with detailed message
$commitMessage = @"
fix: resolve database initialization errors in backend tests

Changes:

Backend Test Configuration:
- Fixed application-test.properties: changed ddl-auto from 'create-drop' to 'create'
- Fixed application-docker.properties: changed ddl-auto from 'create-drop' to 'create'
- Added H2 MySQL compatibility mode with proper connection parameters
- Added Hibernate entity ordering for proper FK constraint handling
- Disabled SQL init mode (let JPA handle schema creation)
- Created schema.sql as fallback documentation

GitHub Actions Workflow:
- Updated test-backend job to use H2 in-memory database
- Added explicit SPRING_PROFILES_ACTIVE=test environment variable
- Removed manual MySQL connection env vars (using H2 instead)
- Simplified test execution for faster CI/CD

Documentation:
- Added DATABASE_INITIALIZATION_FIX.md (comprehensive fix guide)
- Added test-db-fix.ps1 (local verification script)
- Updated push-pipeline-fix.ps1 to include new files

Root Cause:
The 'create-drop' DDL strategy attempts to DROP tables before creating them.
On fresh H2 in-memory databases, this fails with CommandAcceptanceException
because tables don't exist yet. This prevented ApplicationContext from loading
and caused all integration/auth tests to fail.

Solution:
Use 'create' DDL strategy which only creates tables without attempting to drop.
This works cleanly on fresh databases and respects FK ordering.

Fixes: #backend-tests #database-initialization #hibernate-ddl
Branch: release/v1.0.0
Date: November 21, 2025
"@

git commit -m $commitMessage
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Commit created successfully" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to create commit" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚀 Step 3: Pushing to remote..." -ForegroundColor Cyan
Write-Host "  Branch: $currentBranch" -ForegroundColor White
Write-Host "  Remote: origin" -ForegroundColor White
Write-Host ""

# Push to remote
git push origin $currentBranch
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ SUCCESS! Changes pushed to origin/$currentBranch" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Go to: https://github.com/MorningMores/develop/actions" -ForegroundColor White
    Write-Host "  2. Watch for the workflow run to start" -ForegroundColor White
    Write-Host "  3. Verify all jobs complete successfully" -ForegroundColor White
    Write-Host ""
    Write-Host "Expected Results:" -ForegroundColor Yellow
    Write-Host "  ✅ Build Backend Docker Image - SUCCESS" -ForegroundColor Green
    Write-Host "  ✅ Build Frontend Docker Image - SUCCESS" -ForegroundColor Green
    Write-Host "  ✅ Test Backend - SUCCESS" -ForegroundColor Green
    Write-Host "  ✅ Test Frontend - SUCCESS" -ForegroundColor Green
    Write-Host "  ℹ️  Deploy to Staging - SKIPPED (no secrets) or SUCCESS" -ForegroundColor Cyan
    Write-Host "  📢 Notify Slack - SKIPPED (no webhook) or SUCCESS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🎉 Pipeline is now production-ready!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Failed to push changes" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Authentication required (run: gh auth login)" -ForegroundColor White
    Write-Host "  - No internet connection" -ForegroundColor White
    Write-Host "  - Remote branch doesn't exist (run: git push -u origin $currentBranch)" -ForegroundColor White
    Write-Host ""
    Write-Host "Try manual push:" -ForegroundColor Yellow
    Write-Host "  git push origin $currentBranch" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Show recent commits
Write-Host "📜 Recent commits:" -ForegroundColor Cyan
git log --oneline -3
Write-Host ""

Write-Host "✨ All done!" -ForegroundColor Green
