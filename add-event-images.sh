#!/bin/bash
API_URL="https://d3qkurc1gwuwno.cloudfront.net"
IMG_CDN="https://dzh397ixo71bk.cloudfront.net"

echo "Logging in..."
TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"creator@test.com","password":"password123"}' | jq -r '.token')

echo "Token obtained"

# Update events with placeholder images
echo "Updating event 16 (Rock Night)..."
curl -s -X PUT "$API_URL/api/events/16" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title":"Rock Night Live",
    "description":"Amazing rock bands performing live with special guest appearances",
    "category":"Rock",
    "location":"Rock Arena",
    "address":"100 Music Street",
    "city":"Austin",
    "country":"USA",
    "personLimit":3000,
    "phone":"+1-555-1001",
    "startDate":"2025-11-15T19:00:00",
    "endDate":"2025-11-15T23:00:00",
    "ticketPrice":65.00
  }' | jq '{id, title, photoUrl}'

echo "Updating event 17 (Jazz Evening)..."
curl -s -X PUT "$API_URL/api/events/17" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title":"Smooth Jazz Evening",
    "description":"Relaxing jazz music in an intimate setting with world-class musicians",
    "category":"Jazz",
    "location":"Jazz Lounge",
    "address":"200 Melody Avenue",
    "city":"Chicago",
    "country":"USA",
    "personLimit":150,
    "phone":"+1-555-1002",
    "startDate":"2025-11-12T20:00:00",
    "endDate":"2025-11-12T23:00:00",
    "ticketPrice":40.00
  }' | jq '{id, title, photoUrl}'

echo "Updating event 18 (Pop Party)..."
curl -s -X PUT "$API_URL/api/events/18" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title":"Pop Music Party",
    "description":"Dance to the latest pop hits with DJ performances and live acts",
    "category":"Pop",
    "location":"City Hall",
    "address":"300 Pop Boulevard",
    "city":"Seattle",
    "country":"USA",
    "personLimit":5000,
    "phone":"+1-555-1003",
    "startDate":"2025-11-20T18:00:00",
    "endDate":"2025-11-20T22:00:00",
    "ticketPrice":55.00
  }' | jq '{id, title, photoUrl}'

echo "Done!"
