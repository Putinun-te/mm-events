#!/bin/bash
set -e

REGION="ap-southeast-1"
BACKEND_URL="http://52.221.197.39:8080"

echo "🚀 Creating API Gateway HTTP API as HTTPS proxy..."

# Create HTTP API
API_ID=$(aws apigatewayv2 create-api \
  --region $REGION \
  --name concert-backend-proxy \
  --protocol-type HTTP \
  --query 'ApiId' \
  --output text 2>/dev/null || aws apigatewayv2 get-apis --region $REGION --query "Items[?Name=='concert-backend-proxy'].ApiId" --output text)

echo "✅ API ID: $API_ID"

# Create integration
INTEGRATION_ID=$(aws apigatewayv2 create-integration \
  --region $REGION \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-method ANY \
  --integration-uri "$BACKEND_URL/{proxy}" \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text 2>/dev/null || aws apigatewayv2 get-integrations --region $REGION --api-id $API_ID --query 'Items[0].IntegrationId' --output text)

echo "✅ Integration ID: $INTEGRATION_ID"

# Create route for all paths
aws apigatewayv2 create-route \
  --region $REGION \
  --api-id $API_ID \
  --route-key 'ANY /{proxy+}' \
  --target "integrations/$INTEGRATION_ID" 2>/dev/null || echo "Route exists"

# Create default stage
aws apigatewayv2 create-stage \
  --region $REGION \
  --api-id $API_ID \
  --stage-name '$default' \
  --auto-deploy 2>/dev/null || echo "Stage exists"

# Get API endpoint
API_ENDPOINT=$(aws apigatewayv2 get-api --region $REGION --api-id $API_ID --query 'ApiEndpoint' --output text)

echo ""
echo "✅ API Gateway HTTPS Proxy created!"
echo ""
echo "🌐 HTTPS Backend URL: $API_ENDPOINT"
echo ""
echo "🧪 Test it:"
echo "  curl $API_ENDPOINT/api/auth/test"
echo ""
echo "🔧 Update frontend .env:"
echo "  BACKEND_BASE_URL=$API_ENDPOINT"
