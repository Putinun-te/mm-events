#!/bin/bash

echo "🔧 Fixing API Gateway directly..."

# List all routes to see what exists
echo "Available routes:"
aws apigatewayv2 get-routes --region ap-southeast-1 --api-id vg3ht9p21k --query 'Items[].{RouteKey:RouteKey,RouteId:RouteId,AuthType:AuthorizationType}' --output table

# Get the route ID for ANY /{proxy+}
ROUTE_ID=$(aws apigatewayv2 get-routes --region ap-southeast-1 --api-id vg3ht9p21k --query 'Items[?contains(RouteKey, `proxy`)].RouteId' --output text)

echo "Route ID: $ROUTE_ID"

if [ -n "$ROUTE_ID" ]; then
  # Update the API Gateway route to remove JWT authorization
  aws apigatewayv2 update-route \
    --region ap-southeast-1 \
    --api-id vg3ht9p21k \
    --route-id $ROUTE_ID \
    --authorization-type NONE
  
  echo "✅ API Gateway route updated directly!"
else
  echo "❌ Could not find proxy route"
fi

echo "The API should now accept POST requests to /api/events"