#!/bin/bash

echo "🚀 Deploying backend to AWS Lambda..."

cd main_backend

# Build the application
echo "Building application..."
mvn clean package -DskipTests

# Build Docker image
echo "Building Docker image..."
docker build -t concert-backend .

# Tag for ECR
ECR_URI="123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/concert-prod-api"
docker tag concert-backend:latest $ECR_URI:latest

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com

# Push to ECR
echo "Pushing to ECR..."
docker push $ECR_URI:latest

# Update Lambda function
echo "Updating Lambda function..."
aws lambda update-function-code \
  --region ap-southeast-1 \
  --function-name concert-prod-api \
  --image-uri $ECR_URI:latest

echo "✅ Backend deployed successfully!"
echo "CloudFront URL will now be used for photo uploads"