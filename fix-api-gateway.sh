#!/bin/bash

echo "🔧 Fixing API Gateway configuration..."

cd infra/terraform/serverless

# Set variables
VARS="-var=project_name=concert \
-var=environment=prod \
-var=region=ap-southeast-1 \
-var=s3_bucket_name=concert-uploads-singapore-123456789012 \
-var=lambda_image_uri=123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/concert-prod-api:latest \
-var=lambda_enable_jwt_authorizer=false"

# Import existing resources
echo "Importing existing resources..."
terraform import $VARS module.lambda_api.aws_iam_role.lambda concert-prod-api-lambda-role 2>/dev/null || true
terraform import $VARS module.rds.aws_db_instance.this concert-prod-db 2>/dev/null || true
terraform import $VARS module.lambda_api.aws_apigatewayv2_api.http vg3ht9p21k 2>/dev/null || true
terraform import $VARS module.lambda_api.aws_apigatewayv2_route.root_proxy vg3ht9p21k/ANY%2F%7Bproxy%2B%7D 2>/dev/null || true

# Apply only the route change
echo "Updating API Gateway route..."
terraform apply $VARS -target=module.lambda_api.aws_apigatewayv2_route.root_proxy -auto-approve

echo "✅ API Gateway configuration updated!"
echo "The API should now accept POST requests to /api/events"