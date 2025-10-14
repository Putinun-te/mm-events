# Backend E2E Tests Runner (Cypress)
# Runs end-to-end tests against running backend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend E2E Tests (Cypress)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking if backend is running..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend is not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the backend server first:" -ForegroundColor Yellow
    Write-Host "  cd main_backend" -ForegroundColor Yellow
    Write-Host "  mvn spring-boot:run" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Change to cypress tests directory
Set-Location main_backend\cypress-tests

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host ""
    Write-Host "Installing Cypress dependencies..." -ForegroundColor Cyan
    npm install
}

Write-Host ""
Write-Host "Running Cypress E2E tests..." -ForegroundColor Cyan
Write-Host ""

# Run Cypress tests
npm run test:e2e

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✓ E2E tests passed!" -ForegroundColor Green
} else {
    Write-Host "✗ E2E tests failed" -ForegroundColor Red
}

Set-Location ..\..

exit $exitCode
