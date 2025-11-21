#!/bin/bash

# Integration Test Script for Concert Platform
# Tests all major functionality including login, booking, profile updates

BASE_URL="https://vg3ht9p21k.execute-api.ap-southeast-1.amazonaws.com"
TEST_USER="ddd"
TEST_PASS="12345678"

echo "🧪 Starting Integration Tests..."
echo "================================"

# Test 1: Login and get token
echo "1️⃣ Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"usernameOrEmail\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}")

echo "Login Response: $LOGIN_RESPONSE"

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token // empty')
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed - no token received"
  exit 1
fi
echo "✅ Login successful - token received"

# Test 2: Get user profile
echo -e "\n2️⃣ Testing Get Profile..."
PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/api/users/profile" \
  -H "Authorization: Bearer $TOKEN")

echo "Profile Response: $PROFILE_RESPONSE"
if echo $PROFILE_RESPONSE | jq -e '.username' > /dev/null; then
  echo "✅ Profile fetch successful"
else
  echo "❌ Profile fetch failed"
fi

# Test 3: Update profile
echo -e "\n3️⃣ Testing Profile Update..."
UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/api/users/profile" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"displayName":"Test User Updated","email":"ddd@dddd.com","phone":"1234567890"}')

echo "Update Response: $UPDATE_RESPONSE"
if echo $UPDATE_RESPONSE | jq -e '.displayName' > /dev/null; then
  echo "✅ Profile update successful"
else
  echo "❌ Profile update failed"
fi

# Test 4: Get events
echo -e "\n4️⃣ Testing Get Events..."
EVENTS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/events/json")
echo "Events Response (first 200 chars): ${EVENTS_RESPONSE:0:200}..."

if echo $EVENTS_RESPONSE | jq -e '.[0].id' > /dev/null; then
  EVENT_ID=$(echo $EVENTS_RESPONSE | jq -r '.[0].id')
  echo "✅ Events fetch successful - using event ID: $EVENT_ID"
else
  echo "❌ Events fetch failed"
  EVENT_ID="1"
fi

# Test 5: Create booking
echo -e "\n5️⃣ Testing Create Booking..."
BOOKING_RESPONSE=$(curl -s -X POST "$BASE_URL/api/bookings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"eventId\":\"$EVENT_ID\",\"quantity\":1}")

echo "Booking Response: $BOOKING_RESPONSE"
if echo $BOOKING_RESPONSE | jq -e '.id' > /dev/null; then
  BOOKING_ID=$(echo $BOOKING_RESPONSE | jq -r '.id')
  echo "✅ Booking creation successful - ID: $BOOKING_ID"
else
  echo "❌ Booking creation failed"
  echo "Error details: $BOOKING_RESPONSE"
fi

# Test 6: Get my bookings
echo -e "\n6️⃣ Testing Get My Bookings..."
MY_BOOKINGS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/bookings/my-bookings" \
  -H "Authorization: Bearer $TOKEN")

echo "My Bookings Response: $MY_BOOKINGS_RESPONSE"
if echo $MY_BOOKINGS_RESPONSE | jq -e '.[0].id' > /dev/null; then
  echo "✅ Get bookings successful"
else
  echo "❌ Get bookings failed"
fi

# Test 7: Test auth endpoint
echo -e "\n7️⃣ Testing Auth Test Endpoint..."
AUTH_TEST_RESPONSE=$(curl -s -X GET "$BASE_URL/api/auth/test" \
  -H "Authorization: Bearer $TOKEN")

echo "Auth Test Response: $AUTH_TEST_RESPONSE"
if echo $AUTH_TEST_RESPONSE | grep -q "authenticated"; then
  echo "✅ Auth test successful"
else
  echo "❌ Auth test failed"
fi

# Test 8: Test CORS preflight
echo -e "\n8️⃣ Testing CORS..."
CORS_RESPONSE=$(curl -s -X OPTIONS "$BASE_URL/api/bookings" \
  -H "Origin: https://d3jivuimmea02r.cloudfront.net" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -I)

echo "CORS Response Headers:"
echo "$CORS_RESPONSE"
if echo "$CORS_RESPONSE" | grep -q "access-control-allow-origin"; then
  echo "✅ CORS configured correctly"
else
  echo "❌ CORS configuration issue"
fi

echo -e "\n🏁 Integration Tests Complete!"
echo "================================"