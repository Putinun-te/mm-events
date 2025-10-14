# Run All Tests - Complete Test Suite
# Runs unit tests, integration tests (if Docker available), and generates reports

param(
    [switch]$SkipIntegration,
    [switch]$SkipE2E
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running Complete Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalErrors = 0

# Backend Unit Tests
Write-Host "[1/5] Backend Unit Tests" -ForegroundColor Magenta
Write-Host "-------------------------" -ForegroundColor Magenta
& .\run-unit-tests.ps1
if ($LASTEXITCODE -ne 0) { $totalErrors++ }
Write-Host ""

# Backend Integration Tests (if Docker is available and not skipped)
if (-not $SkipIntegration) {
    Write-Host "[2/5] Backend Integration Tests" -ForegroundColor Magenta
    Write-Host "-------------------------------" -ForegroundColor Magenta
    
    $dockerRunning = $false
    try {
        $null = docker ps 2>$null
        $dockerRunning = $true
    } catch {
        Write-Host "⚠ Skipping integration tests (Docker not running)" -ForegroundColor Yellow
    }
    
    if ($dockerRunning) {
        & .\run-integration-tests.ps1
        if ($LASTEXITCODE -ne 0) { $totalErrors++ }
    }
    Write-Host ""
} else {
    Write-Host "[2/5] Backend Integration Tests - SKIPPED" -ForegroundColor Yellow
    Write-Host ""
}

# Frontend Unit Tests
Write-Host "[3/5] Frontend Unit Tests" -ForegroundColor Magenta
Write-Host "-------------------------" -ForegroundColor Magenta
& .\run-frontend-tests.ps1
if ($LASTEXITCODE -ne 0) { $totalErrors++ }
Write-Host ""

# Generate coverage reports
Write-Host "[4/5] Generating Coverage Reports" -ForegroundColor Magenta
Write-Host "---------------------------------" -ForegroundColor Magenta

Set-Location main_backend
Write-Host "Backend coverage report..." -ForegroundColor Cyan
& mvn jacoco:report -B
Set-Location ..

Set-Location main_frontend\concert1
Write-Host "Frontend coverage report..." -ForegroundColor Cyan
npm run test:coverage
Set-Location ..\..

Write-Host ""
Write-Host "Coverage Reports:" -ForegroundColor Cyan
Write-Host "  Backend:  main_backend/target/site/jacoco/index.html" -ForegroundColor Yellow
Write-Host "  Frontend: main_frontend/concert1/coverage/index.html" -ForegroundColor Yellow
Write-Host ""

# Summary
Write-Host "[5/5] Test Summary" -ForegroundColor Magenta
Write-Host "-----------------" -ForegroundColor Magenta

if ($totalErrors -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  - Review coverage reports" -ForegroundColor Yellow
    Write-Host "  - Run E2E tests if servers are running" -ForegroundColor Yellow
    Write-Host "  - Commit your changes" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "✗ $totalErrors test suite(s) failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please fix the failing tests before committing." -ForegroundColor Yellow
    exit 1
}
