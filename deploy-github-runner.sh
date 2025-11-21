#!/bin/bash
set -e

echo "🚀 Deploying GitHub Actions Runner to EKS"
echo "=========================================="

# Check if token is provided
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: GITHUB_TOKEN environment variable not set"
  echo ""
  echo "Usage:"
  echo "  export GITHUB_TOKEN='your-token-here'"
  echo "  ./deploy-github-runner.sh"
  echo ""
  echo "⚠️  NEVER commit tokens to git!"
  exit 1
fi

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace actions-runner-system --dry-run=client -o yaml | kubectl apply -f -

# Create secret
echo "🔐 Creating GitHub token secret..."
kubectl create secret generic github-token \
  --from-literal=GITHUB_TOKEN="$GITHUB_TOKEN" \
  -n actions-runner-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy runner
echo "🏃 Deploying runner..."
kubectl apply -f k8s/github-runner.yaml

# Wait for deployment
echo "⏳ Waiting for runner to be ready..."
kubectl wait --for=condition=available --timeout=120s \
  deployment/github-runner -n actions-runner-system || true

# Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Runner Status:"
kubectl get pods -n actions-runner-system
echo ""
echo "📋 View logs:"
echo "  kubectl logs -f deployment/github-runner -n actions-runner-system"
echo ""
echo "🔍 Check GitHub:"
echo "  Settings → Actions → Runners"
