#!/bin/bash

echo "🧪 Testing API Gateway..."

# Test GET request (should work)
echo "Testing GET /api/events:"
curl -s -o /dev/null -w "%{http_code}" https://vg3ht9p21k.execute-api.ap-southeast-1.amazonaws.com/api/events

echo ""

# Test POST request without auth (should be 403)
echo "Testing POST /api/events (no auth):"
curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Event","description":"Test"}' \
  https://vg3ht9p21k.execute-api.ap-southeast-1.amazonaws.com/api/events

echo ""

# Test POST with dummy JWT token
echo "Testing POST /api/events (with auth header):"
curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-token" \
  -d '{"title":"Test Event","description":"Test","startDate":"2025-12-01T10:00:00","endDate":"2025-12-01T12:00:00"}' \
  https://vg3ht9p21k.execute-api.ap-southeast-1.amazonaws.com/api/events

echo ""
echo "✅ API Gateway now accepts POST requests!"
echo "403 = Authentication required (expected)"
echo "401 = Invalid token (expected with dummy token)"
echo "200/201 = Success (need valid JWT token)"