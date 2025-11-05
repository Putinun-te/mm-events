#!/usr/bin/env bash
# Deployment script for Concert production infrastructure

set -euo pipefail

ACCOUNT_ID=${AWS_ACCOUNT_ID:-123456789012}
REGION=${AWS_REGION:-us-east-1}
REPO_NAME=concert-api
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

echo "=== Concert Production Deployment ==="
echo "Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo ""

# Step 1: Ensure ECR repository exists
echo "[1/5] Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Creating ECR repository..."
  aws ecr create-repository \
    --repository-name "$REPO_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --region "$REGION"
else
  echo "ECR repository exists"
fi

# Step 2: Build and push Docker image
echo ""
echo "[2/5] Building Docker image..."
docker build -t ${REPO_NAME}:latest "$PROJECT_ROOT/main_backend"

echo "Logging in to ECR..."
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "Tagging and pushing image..."
docker tag ${REPO_NAME}:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest

# Step 3: Initialize Terraform
echo ""
echo "[3/5] Initializing Terraform..."
cd "$PROJECT_ROOT/infra/terraform/production"
terraform init

# Step 4: Plan
echo ""
echo "[4/5] Planning infrastructure..."
terraform plan -out=tfplan

# Step 5: Apply
echo ""
echo "[5/5] Applying infrastructure..."
read -p "Apply changes? (yes/no): " confirm
if [[ "$confirm" == "yes" ]]; then
  terraform apply tfplan
  rm -f tfplan
  
  echo ""
  echo "=== Deployment Complete ==="
  echo ""
  echo "API Endpoint:"
  terraform output -raw api_endpoint
  echo ""
  echo ""
  echo "Cognito User Pool ID:"
  terraform output -raw cognito_user_pool_id
  echo ""
  echo ""
  echo "Cognito App Client ID:"
  terraform output -raw cognito_app_client_id
  echo ""
  echo ""
  echo "Next steps:"
  echo "1. Update frontend config with the outputs above"
  echo "2. Configure custom domain + ACM certificate if needed"
  echo "3. Set up AWS Budgets alarm at \$50/month"
  echo "4. Configure IAM groups: cd ../../aws && ./iam-group-maintenance.sh provision"
else
  echo "Deployment cancelled"
  rm -f tfplan
  exit 1
fi
