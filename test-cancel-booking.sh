#!/bin/bash

# Test script to verify participant count reduction on booking cancellation
# This simulates what happens when a user cancels their booking

echo "================================"
echo "Testing Booking Cancellation"
echo "================================"
echo ""

# Get JWT token (you'll need to login first)
echo "Step 1: Login to get JWT token"
echo "Please provide credentials:"
echo "Email: test@test.com"
echo "Password: password123"
echo ""

# Login and get token
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login failed. Token not received."
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful! Token received."
echo ""

# Check current participant count
echo "Step 2: Check current participant count for event ID 1760360780023"
BEFORE_DATA=$(cat main_frontend/concert1/data/events.json | jq '.[] | select(.id == 1760360780023)')
BEFORE_COUNT=$(echo $BEFORE_DATA | jq '.participantsCount')
BEFORE_PARTICIPANTS=$(echo $BEFORE_DATA | jq '.participants | length')

echo "📊 Before cancellation:"
echo "   Total tickets booked: $BEFORE_COUNT"
echo "   Number of participants: $BEFORE_PARTICIPANTS"
echo ""

# Get user's bookings
echo "Step 3: Fetch user's bookings"
BOOKINGS=$(curl -s -X GET http://localhost:8080/api/bookings/me \
  -H "Authorization: Bearer $TOKEN")

BOOKING_ID=$(echo $BOOKINGS | jq -r '.[0].id')
EVENT_ID=$(echo $BOOKINGS | jq -r '.[0].eventId')

if [ "$BOOKING_ID" = "null" ]; then
  echo "❌ No bookings found for this user"
  exit 1
fi

echo "✅ Found booking:"
echo "   Booking ID: $BOOKING_ID"
echo "   Event ID: $EVENT_ID"
echo ""

# Cancel the booking
echo "Step 4: Cancel the booking"
CANCEL_RESPONSE=$(curl -s -X DELETE http://localhost:8080/api/bookings/$BOOKING_ID \
  -H "Authorization: Bearer $TOKEN" \
  -w "\nHTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$CANCEL_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)

if [ "$HTTP_STATUS" = "204" ] || [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Booking cancelled successfully (HTTP $HTTP_STATUS)"
else
  echo "❌ Booking cancellation failed (HTTP $HTTP_STATUS)"
  echo "Response: $CANCEL_RESPONSE"
  exit 1
fi
echo ""

# Remove participant from event
echo "Step 5: Remove participant from event participants list"
LEAVE_RESPONSE=$(curl -s -X POST http://localhost:3000/api/events/json/$EVENT_ID/leave \
  -H "Authorization: Bearer $TOKEN")

echo "Leave response: $LEAVE_RESPONSE"
echo ""

# Check participant count after cancellation
echo "Step 6: Verify participant count reduced correctly"
sleep 1
AFTER_DATA=$(cat main_frontend/concert1/data/events.json | jq '.[] | select(.id == 1760360780023)')
AFTER_COUNT=$(echo $AFTER_DATA | jq '.participantsCount')
AFTER_PARTICIPANTS=$(echo $AFTER_DATA | jq '.participants | length')

echo "📊 After cancellation:"
echo "   Total tickets booked: $AFTER_COUNT"
echo "   Number of participants: $AFTER_PARTICIPANTS"
echo ""

# Calculate the difference
DIFF=$((BEFORE_COUNT - AFTER_COUNT))

echo "================================"
echo "📈 Results:"
echo "================================"
echo "Tickets reduced by: $DIFF"
echo ""

if [ $DIFF -gt 0 ]; then
  echo "✅ SUCCESS! Participant count correctly decreased by $DIFF tickets"
else
  echo "❌ FAILED! Participant count did not decrease correctly"
  echo "   Expected: decrease by ticket quantity"
  echo "   Actual: decreased by $DIFF"
fi
echo ""
