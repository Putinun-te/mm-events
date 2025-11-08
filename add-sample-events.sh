#!/bin/bash

# Add sample events via API
API_URL="https://d3qkurc1gwuwno.cloudfront.net"

# Login to get token
echo "Logging in..."
TOKEN=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"user1@test.com","password":"password123"}' | jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "Failed to login"
  exit 1
fi

echo "Token obtained: ${TOKEN:0:20}..."

# Create sample events
echo "Creating sample events..."

# Event 1: Rock Concert
curl -s -X POST "$API_URL/api/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Summer Rock Festival 2025",
    "description": "The biggest rock festival of the year featuring top bands from around the world",
    "category": "Rock",
    "location": "Central Park",
    "address": "123 Park Avenue",
    "city": "New York",
    "country": "USA",
    "personLimit": 5000,
    "phone": "+1-555-0101",
    "startDate": "2025-07-15T18:00:00",
    "endDate": "2025-07-15T23:00:00",
    "ticketPrice": 89.99
  }' | jq .

# Event 2: Jazz Night
curl -s -X POST "$API_URL/api/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Jazz Under the Stars",
    "description": "An intimate evening of smooth jazz with renowned artists",
    "category": "Jazz",
    "location": "Blue Note Club",
    "address": "456 Jazz Street",
    "city": "New Orleans",
    "country": "USA",
    "personLimit": 200,
    "phone": "+1-555-0102",
    "startDate": "2025-06-20T20:00:00",
    "endDate": "2025-06-20T23:30:00",
    "ticketPrice": 45.00
  }' | jq .

# Event 3: Pop Concert
curl -s -X POST "$API_URL/api/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Pop Sensation World Tour",
    "description": "Chart-topping hits performed live by international pop stars",
    "category": "Pop",
    "location": "Madison Square Garden",
    "address": "789 Arena Blvd",
    "city": "Los Angeles",
    "country": "USA",
    "personLimit": 10000,
    "phone": "+1-555-0103",
    "startDate": "2025-08-10T19:00:00",
    "endDate": "2025-08-10T22:00:00",
    "ticketPrice": 125.00
  }' | jq .

# Event 4: EDM Festival
curl -s -X POST "$API_URL/api/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Electric Dreams Festival",
    "description": "Non-stop electronic dance music with world-class DJs",
    "category": "EDM",
    "location": "Beach Arena",
    "address": "321 Ocean Drive",
    "city": "Miami",
    "country": "USA",
    "personLimit": 15000,
    "phone": "+1-555-0104",
    "startDate": "2025-09-05T16:00:00",
    "endDate": "2025-09-06T04:00:00",
    "ticketPrice": 99.00
  }' | jq .

# Event 5: Classical Concert
curl -s -X POST "$API_URL/api/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Symphony Orchestra Gala",
    "description": "A magnificent evening of classical masterpieces",
    "category": "Jazz",
    "location": "Concert Hall",
    "address": "555 Symphony Lane",
    "city": "Boston",
    "country": "USA",
    "personLimit": 800,
    "phone": "+1-555-0105",
    "startDate": "2025-06-01T19:30:00",
    "endDate": "2025-06-01T22:00:00",
    "ticketPrice": 75.00
  }' | jq .

echo "Sample events created successfully!"
