#!/bin/bash

# System Stability Verification Script
# This script checks the health of all services

echo "======================================"
echo "System Stability Check"
echo "Date: $(date)"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker containers
echo "1. Checking Docker Containers..."
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Docker containers are running${NC}"
    docker-compose ps | grep "concert-"
else
    echo -e "${RED}✗ Some containers are not running${NC}"
    docker-compose ps
fi
echo ""

# Check MySQL
echo "2. Checking MySQL..."
if docker exec concert-mysql mysqladmin ping -h localhost -u concert_user -pconcert_password 2>&1 | grep -q "mysqld is alive"; then
    echo -e "${GREEN}✓ MySQL is healthy${NC}"
else
    echo -e "${RED}✗ MySQL is not responding${NC}"
fi
echo ""

# Check Backend
echo "3. Checking Backend (Spring Boot)..."
if curl -s http://localhost:8080/api/auth/test | grep -q "Auth API is working"; then
    echo -e "${GREEN}✓ Backend is responding${NC}"
else
    echo -e "${RED}✗ Backend is not responding${NC}"
fi
echo ""

# Check Frontend
echo "4. Checking Frontend (Nuxt)..."
if curl -s http://localhost:3000/concert/ | grep -q "<!DOCTYPE html>"; then
    echo -e "${GREEN}✓ Frontend is serving pages${NC}"
else
    echo -e "${RED}✗ Frontend is not responding${NC}"
fi
echo ""

# Check for errors in logs
echo "5. Checking Recent Errors..."
echo "Backend errors (last 10 lines):"
backend_errors=$(docker logs concert-backend --tail 100 2>&1 | grep -E "ERROR|Exception" | tail -10)
if [ -z "$backend_errors" ]; then
    echo -e "${GREEN}✓ No recent errors${NC}"
else
    echo -e "${YELLOW}⚠ Found errors:${NC}"
    echo "$backend_errors"
fi
echo ""

echo "Frontend errors (last 10 lines):"
frontend_errors=$(docker logs concert-frontend --tail 100 2>&1 | grep -E "ERROR|error|Failed" | grep -v "WARN" | tail -10)
if [ -z "$frontend_errors" ]; then
    echo -e "${GREEN}✓ No recent errors${NC}"
else
    echo -e "${YELLOW}⚠ Found errors:${NC}"
    echo "$frontend_errors"
fi
echo ""

# Summary
echo "======================================"
echo "Summary"
echo "======================================"
echo "Run this script anytime to verify system health"
echo "Access points:"
echo "  - Frontend: http://localhost:3000/concert/"
echo "  - Backend:  http://localhost:8080"
echo "  - MySQL:    localhost:3306"
echo ""
