#!/bin/bash
API_URL="https://d3qkurc1gwuwno.cloudfront.net"

echo "Logging in..."
TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"creator@test.com","password":"password123"}' | jq -r '.token')

echo "Token obtained"

echo "Creating Rock Festival (Nov 15)..."
curl -s -X POST "$API_URL/api/events" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Rock Night Live","description":"Amazing rock bands performing live","category":"Rock","location":"Rock Arena","address":"100 Music St","city":"Austin","country":"USA","personLimit":3000,"phone":"+1-555-1001","startDate":"2025-11-15T19:00:00","endDate":"2025-11-15T23:00:00","ticketPrice":65.00}' | jq '{id, title}'

echo "Creating Jazz Evening (Nov 12)..."
curl -s -X POST "$API_URL/api/events" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Smooth Jazz Evening","description":"Relaxing jazz music","category":"Jazz","location":"Jazz Lounge","address":"200 Melody Ave","city":"Chicago","country":"USA","personLimit":150,"phone":"+1-555-1002","startDate":"2025-11-12T20:00:00","endDate":"2025-11-12T23:00:00","ticketPrice":40.00}' | jq '{id, title}'

echo "Creating Pop Party (Nov 20)..."
curl -s -X POST "$API_URL/api/events" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Pop Music Party","description":"Dance to the latest pop hits","category":"Pop","location":"City Hall","address":"300 Pop Blvd","city":"Seattle","country":"USA","personLimit":5000,"phone":"+1-555-1003","startDate":"2025-11-20T18:00:00","endDate":"2025-11-20T22:00:00","ticketPrice":55.00}' | jq '{id, title}'

echo "Creating EDM Night (Nov 25)..."
curl -s -X POST "$API_URL/api/events" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"EDM Rave Night","description":"Electronic beats all night","category":"EDM","location":"Warehouse 51","address":"400 Bass Dr","city":"Las Vegas","country":"USA","personLimit":8000,"phone":"+1-555-1004","startDate":"2025-11-25T21:00:00","endDate":"2025-11-26T05:00:00","ticketPrice":75.00}' | jq '{id, title}'

echo "Creating Indie Concert (Nov 10)..."
curl -s -X POST "$API_URL/api/events" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Indie Music Showcase","description":"Discover new indie artists","category":"Rock","location":"Small Stage","address":"500 Indie Ln","city":"Portland","country":"USA","personLimit":500,"phone":"+1-555-1005","startDate":"2025-11-10T19:30:00","endDate":"2025-11-10T22:30:00","ticketPrice":30.00}' | jq '{id, title}'

echo "Done! Checking events..."
curl -s "$API_URL/api/events?page=0&size=20" | jq '.totalElements'
