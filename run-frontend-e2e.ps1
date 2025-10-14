# Frontend E2E Tests Runner (Cypress)
# Runs end-to-end tests against running frontend and backend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Frontend E2E Tests (Cypress)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking if backend is running..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Backend is not running!" -ForegroundColor Red
    Write-Host "Please start the backend first" -ForegroundColor Yellow
    exit 1
}

# Check if frontend is running
Write-Host "Checking if frontend is running..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/concert" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Frontend is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Frontend is not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the frontend first:" -ForegroundColor Yellow
    Write-Host "  cd main_frontend/concert1" -ForegroundColor Yellow
    Write-Host "  npm run dev" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Change to frontend directory
Set-Location main_frontend\concert1

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host ""
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    npm install
}

Write-Host ""
Write-Host "Running Cypress E2E tests..." -ForegroundColor Cyan
Write-Host ""

# Run Cypress tests
npm run test:e2e:headless

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✓ E2E tests passed!" -ForegroundColor Green
} else {
    Write-Host "✗ E2E tests failed" -ForegroundColor Red
}

Set-Location ..\..

exit $exitCode
