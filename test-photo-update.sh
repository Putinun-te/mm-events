#!/bin/bash
TOKEN=$(curl -s -X POST "https://d3qkurc1gwuwno.cloudfront.net/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"creator@test.com","password":"password123"}' | jq -r '.token')

echo "Testing photo update..."
curl -s -X PUT "https://d3qkurc1gwuwno.cloudfront.net/api/events/20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title":"Indie Music Showcase",
    "description":"Discover new indie artists",
    "category":"Rock",
    "location":"Small Stage",
    "address":"500 Indie Ln",
    "city":"Portland",
    "country":"USA",
    "personLimit":500,
    "phone":"+1-555-1005",
    "startDate":"2025-11-10T19:30:00",
    "endDate":"2025-11-10T22:30:00",
    "ticketPrice":30.00,
    "photoUrl":"https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800"
  }' | jq .

echo -e "\n\nVerifying..."
curl -s "https://d3qkurc1gwuwno.cloudfront.net/api/events/20" | jq '{id, title, photoUrl}'
