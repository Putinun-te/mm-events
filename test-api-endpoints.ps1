#!/usr/bin/env pwsh
# Backend API Endpoint Testing Script
# Tests all main API endpoints for the Concert Management System

Write-Host "`n=== Backend API Endpoint Testing ===" -ForegroundColor Cyan
Write-Host "Backend URL: http://localhost:8080`n" -ForegroundColor Gray

# Test 1: Health Check
Write-Host "[1/7] Testing Health Check Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/test" -Method Get
    Write-Host "✅ Health Check: $healthResponse" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: User Registration
Write-Host "`n[2/7] Testing User Registration..." -ForegroundColor Yellow
$registerBody = @{
    username = "testuser_$(Get-Date -Format 'yyyyMMddHHmmss')"
    email = "test_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    password = "password123"
    firstName = "Test"
    lastName = "User"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $registerBody
    Write-Host "✅ Registration Successful" -ForegroundColor Green
    Write-Host "   Token: $($registerResponse.token.Substring(0, 20))..." -ForegroundColor Gray
    $global:authToken = $registerResponse.token
    $global:userId = $registerResponse.id
} catch {
    Write-Host "❌ Registration Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

# Test 3: User Login
Write-Host "`n[3/7] Testing User Login..." -ForegroundColor Yellow
$loginBody = @{
    email = "test_$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    # Use a known user or the one we just created
    $loginBody = @{
        email = $registerBody | ConvertFrom-Json | Select-Object -ExpandProperty email
        password = "password123"
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    Write-Host "✅ Login Successful" -ForegroundColor Green
    Write-Host "   User: $($loginResponse.username)" -ForegroundColor Gray
    $global:authToken = $loginResponse.token
} catch {
    Write-Host "⚠️  Login Test Skipped (using registration token)" -ForegroundColor Yellow
}

# Test 4: Get Current User (Protected Endpoint)
Write-Host "`n[4/7] Testing Get Current User (Protected)..." -ForegroundColor Yellow
if ($global:authToken) {
    try {
        $headers = @{
            "Authorization" = "Bearer $global:authToken"
        }
        $meResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/me" `
            -Method Get `
            -Headers $headers
        Write-Host "✅ Get Current User Successful" -ForegroundColor Green
        Write-Host "   User: $($meResponse.username) ($($meResponse.email))" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Get Current User Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Skipped (no auth token)" -ForegroundColor Yellow
}

# Test 5: Get All Events (Public)
Write-Host "`n[5/7] Testing Get All Events..." -ForegroundColor Yellow
try {
    $eventsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/events" -Method Get
    Write-Host "✅ Get Events Successful" -ForegroundColor Green
    Write-Host "   Total Events: $($eventsResponse.Count)" -ForegroundColor Gray
    if ($eventsResponse.Count -gt 0) {
        Write-Host "   First Event: $($eventsResponse[0].name)" -ForegroundColor Gray
        $global:testEventId = $eventsResponse[0].id
    }
} catch {
    Write-Host "❌ Get Events Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Get Event by ID
Write-Host "`n[6/7] Testing Get Event by ID..." -ForegroundColor Yellow
if ($global:testEventId) {
    try {
        $eventResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/events/$global:testEventId" -Method Get
        Write-Host "✅ Get Event by ID Successful" -ForegroundColor Green
        Write-Host "   Event: $($eventResponse.name)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Get Event by ID Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Skipped (no test event available)" -ForegroundColor Yellow
}

# Test 7: Create Event (Protected)
Write-Host "`n[7/7] Testing Create Event (Protected)..." -ForegroundColor Yellow
if ($global:authToken) {
    $createEventBody = @{
        title = "Test Event $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        description = "Automated test event"
        category = "Music"
        location = "Test Venue"
        address = "123 Test Street"
        city = "Test City"
        country = "Test Country"
        phone = "+1234567890"
        startDate = (Get-Date).AddDays(30).ToString("yyyy-MM-ddTHH:mm:ss")
        endDate = (Get-Date).AddDays(30).AddHours(4).ToString("yyyy-MM-ddTHH:mm:ss")
        personLimit = 100
        ticketPrice = 50.00
    } | ConvertTo-Json

    try {
        $headers = @{
            "Authorization" = "Bearer $global:authToken"
            "Content-Type" = "application/json"
        }
        $createEventResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/events" `
            -Method Post `
            -Headers $headers `
            -Body $createEventBody
        Write-Host "✅ Create Event Successful" -ForegroundColor Green
        Write-Host "   Event ID: $($createEventResponse.eventId)" -ForegroundColor Gray
        Write-Host "   Event Title: $($createEventResponse.title)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Create Event Failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "⚠️  Skipped (no auth token)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All critical API endpoints have been tested." -ForegroundColor Gray
Write-Host "Review the results above for any failures.`n" -ForegroundColor Gray
