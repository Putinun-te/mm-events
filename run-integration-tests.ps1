# Backend Integration Tests Runner
# Runs integration tests that require Docker/MySQL

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running Backend Integration Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
$dockerRunning = $false
try {
    $null = docker ps 2>$null
    $dockerRunning = $true
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

# Set Java Home to JDK 21
$jdk21Path = "C:\Program Files\Java\jdk-21"
if (Test-Path $jdk21Path) {
    $env:JAVA_HOME = $jdk21Path
    Write-Host "✓ Using JDK 21: $env:JAVA_HOME" -ForegroundColor Green
} else {
    Write-Host "⚠ JDK 21 not found at $jdk21Path" -ForegroundColor Yellow
}

# Change to backend directory
Set-Location main_backend

Write-Host ""
Write-Host "Running integration tests (requires Docker)..." -ForegroundColor Cyan
Write-Host ""

# Run integration tests
& mvn verify -P integration-tests -B

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✓ Integration tests passed!" -ForegroundColor Green
} else {
    Write-Host "✗ Integration tests failed with exit code: $exitCode" -ForegroundColor Red
}

Set-Location ..

exit $exitCode
