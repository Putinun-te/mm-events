# Frontend Unit Tests Runner
# Runs Vitest unit tests

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Frontend Unit Tests (Vitest)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to frontend directory
Set-Location main_frontend\concert1

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    npm install
    Write-Host ""
}

Write-Host "Running unit tests..." -ForegroundColor Cyan
Write-Host ""

# Run tests
npm run test

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✓ Unit tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run with coverage:" -ForegroundColor Cyan
    Write-Host "  npm run test:coverage" -ForegroundColor Yellow
} else {
    Write-Host "✗ Unit tests failed" -ForegroundColor Red
}

Set-Location ..\..

exit $exitCode
