#!/bin/bash
TOKEN=$(curl -s -X POST "https://d3qkurc1gwuwno.cloudfront.net/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"usernameOrEmail":"creator@test.com","password":"password123"}' | jq -r '.token')

echo "Testing upload URL generation..."
curl -s -X POST "https://d3qkurc1gwuwno.cloudfront.net/api/events/16/photo/upload-url?filename=test.jpg" \
  -H "Authorization: Bearer $TOKEN" | jq .
