#!/bin/bash

# Test current authentication status
BASE_URL="https://vg3ht9p21k.execute-api.ap-southeast-1.amazonaws.com"

echo "🔍 Testing Authentication..."

# Get fresh token
echo "1. Getting fresh token..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"ddd","password":"12345678"}')

echo "Login response: $LOGIN_RESPONSE"

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Failed to get token"
  exit 1
fi

echo "✅ Got token: ${TOKEN:0:50}..."

# Test booking with fresh token
echo -e "\n2. Testing booking..."
BOOKING_RESPONSE=$(curl -s -X POST "$BASE_URL/api/bookings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"eventId":"1","quantity":1}' -w "\nHTTP_CODE:%{http_code}")

echo "Booking response: $BOOKING_RESPONSE"

# Test profile update with fresh token  
echo -e "\n3. Testing profile update..."
PROFILE_RESPONSE=$(curl -s -X PUT "$BASE_URL/api/users/profile" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"firstName":"Test","lastName":"User","phone":"1234567890"}' -w "\nHTTP_CODE:%{http_code}")

echo "Profile response: $PROFILE_RESPONSE"

echo -e "\n✅ Test complete"