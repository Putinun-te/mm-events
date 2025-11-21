# Test Database Fix Verification Script
# Run this to verify the database initialization fix works locally

Write-Host "🧪 Backend Test Database Fix - Verification" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "main_backend\pom.xml")) {
    Write-Host "❌ Error: Run this from the repository root (c:\Devop\develop)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Test Verification Steps:" -ForegroundColor Yellow
Write-Host ""

# Step 1: Clean build
Write-Host "Step 1: Clean previous build artifacts..." -ForegroundColor Cyan
cd main_backend
mvn clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Maven clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Run tests with H2 profile
Write-Host "Step 2: Running tests with H2 in-memory database (test profile)..." -ForegroundColor Cyan
Write-Host "Command: mvn -Dspring.profiles.active=test test" -ForegroundColor Gray
Write-Host ""

$env:SPRING_PROFILES_ACTIVE = "test"
mvn -Dspring.profiles.active=test -DforkCount=1 -DreuseForks=false test

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ SUCCESS! All tests passed!" -ForegroundColor Green
    Write-Host ""
    
    # Check for test reports
    if (Test-Path "target\surefire-reports") {
        Write-Host "📊 Test Results:" -ForegroundColor Cyan
        $testFiles = Get-ChildItem "target\surefire-reports\*.xml"
        Write-Host "  Total test report files: $($testFiles.Count)" -ForegroundColor White
        
        # Count tests
        $totalTests = 0
        $failedTests = 0
        foreach ($file in $testFiles) {
            $content = Get-Content $file.FullName -Raw
            if ($content -match 'tests="(\d+)"') {
                $totalTests += [int]$matches[1]
            }
            if ($content -match 'failures="(\d+)"') {
                $failedTests += [int]$matches[1]
            }
        }
        
        Write-Host "  Total tests executed: $totalTests" -ForegroundColor White
        Write-Host "  Tests passed: $($totalTests - $failedTests)" -ForegroundColor Green
        if ($failedTests -gt 0) {
            Write-Host "  Tests failed: $failedTests" -ForegroundColor Red
        }
    }
    
    # Check JaCoCo coverage
    if (Test-Path "target\site\jacoco\index.html") {
        Write-Host ""
        Write-Host "📈 Code Coverage Report Generated:" -ForegroundColor Cyan
        Write-Host "  Location: main_backend\target\site\jacoco\index.html" -ForegroundColor White
        Write-Host ""
        $openCoverage = Read-Host "Open coverage report in browser? (y/n)"
        if ($openCoverage -eq "y") {
            Start-Process "target\site\jacoco\index.html"
        }
    }
    
} else {
    Write-Host ""
    Write-Host "❌ FAILED! Tests did not pass" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check test reports in: main_backend\target\surefire-reports" -ForegroundColor Yellow
    
    # Show recent test failures
    if (Test-Path "target\surefire-reports") {
        Write-Host ""
        Write-Host "Recent test output files:" -ForegroundColor Yellow
        Get-ChildItem "target\surefire-reports\*.txt" | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }
    }
    
    exit 1
}

Write-Host ""
Write-Host "🎯 Verification Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Database initialization: WORKING" -ForegroundColor Green
Write-Host "  ✅ H2 in-memory database: CONFIGURED" -ForegroundColor Green
Write-Host "  ✅ Hibernate DDL (create): WORKING" -ForegroundColor Green
Write-Host "  ✅ Entity relationships: VALID" -ForegroundColor Green
Write-Host "  ✅ Test execution: SUCCESS" -ForegroundColor Green
Write-Host ""

# Step 3: Optional - Run specific integration tests
Write-Host "Optional: Run specific integration test classes" -ForegroundColor Yellow
$runSpecific = Read-Host "Run AuthIntegrationTest separately? (y/n)"
if ($runSpecific -eq "y") {
    Write-Host ""
    Write-Host "Running AuthIntegrationTest..." -ForegroundColor Cyan
    mvn -Dspring.profiles.active=test -Dtest=AuthIntegrationTest test
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AuthIntegrationTest passed!" -ForegroundColor Green
    } else {
        Write-Host "❌ AuthIntegrationTest failed!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✨ Verification complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review DATABASE_INITIALIZATION_FIX.md for details" -ForegroundColor White
Write-Host "  2. Commit and push changes to trigger GitHub Actions" -ForegroundColor White
Write-Host "  3. Monitor: https://github.com/MorningMores/develop/actions" -ForegroundColor White
Write-Host ""

cd ..
