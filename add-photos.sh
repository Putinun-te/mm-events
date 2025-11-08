#!/bin/bash
API_URL="https://d3qkurc1gwuwno.cloudfront.net"

TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"creator@test.com","password":"password123"}' | jq -r '.token')

echo "Adding photos to events..."

# Event 20 - Indie Music
curl -s -X PUT "$API_URL/api/events/20" \
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
  }' | jq '{id, title, photoUrl}'

# Event 17 - Jazz
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
    "ticketPrice":40.00,
    "photoUrl":"https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800"
  }' | jq '{id, title, photoUrl}'

# Event 16 - Rock
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
    "ticketPrice":65.00,
    "photoUrl":"https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800"
  }' | jq '{id, title, photoUrl}'

# Event 18 - Pop
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
    "ticketPrice":55.00,
    "photoUrl":"https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800"
  }' | jq '{id, title, photoUrl}'

# Event 19 - EDM
curl -s -X PUT "$API_URL/api/events/19" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title":"EDM Rave Night",
    "description":"Non-stop electronic dance music",
    "category":"EDM",
    "location":"Beach Arena",
    "address":"400 Bass Dr",
    "city":"Las Vegas",
    "country":"USA",
    "personLimit":8000,
    "phone":"+1-555-1004",
    "startDate":"2025-11-25T21:00:00",
    "endDate":"2025-11-26T05:00:00",
    "ticketPrice":75.00,
    "photoUrl":"https://images.unsplash.com/photo-1571266028243-d220c6e2e8e2?w=800"
  }' | jq '{id, title, photoUrl}'

echo "Done!"
