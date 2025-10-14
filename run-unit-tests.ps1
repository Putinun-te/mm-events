# Backend Unit Tests Runner
# Runs fast unit tests without Docker dependencies

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running Backend Unit Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Try to find JDK 21
$jdkPaths = @(
    "C:\Program Files\Java\jdk-21",
    "C:\Program Files\Eclipse Adoptium\jdk-21*",
    "C:\Program Files\Microsoft\jdk-21*",
    "$env:ProgramFiles\Java\jdk-21*"
)

$jdkFound = $false
foreach ($path in $jdkPaths) {
    $resolved = Get-Item $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($resolved) {
        $env:JAVA_HOME = $resolved.FullName
        $jdkFound = $true
        Write-Host "✓ Using JDK: $env:JAVA_HOME" -ForegroundColor Green
        break
    }
}

if (-not $jdkFound) {
    Write-Host "⚠ JDK 21 not found in standard locations" -ForegroundColor Yellow
    Write-Host "Please install JDK 21 or set JAVA_HOME manually" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Attempting to use system Java..." -ForegroundColor Cyan
}

# Change to backend directory
Set-Location main_backend

Write-Host ""
Write-Host "Running unit tests (excludes integration and Docker tests)..." -ForegroundColor Cyan
Write-Host ""

# Run unit tests only using Maven wrapper
& .\mvnw.cmd test -P unit-tests -B

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✓ Unit tests passed!" -ForegroundColor Green
} else {
    Write-Host "✗ Unit tests failed with exit code: $exitCode" -ForegroundColor Red
}

Write-Host ""
Write-Host "Coverage report: main_backend/target/site/jacoco/index.html" -ForegroundColor Cyan

Set-Location ..

exit $exitCode
