#!/bin/bash
set -e

echo "🔧 Fixing GitHub Runner Token"
echo "=============================="
echo ""

# Check if token is provided
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: GITHUB_TOKEN environment variable not set"
  echo ""
  echo "Usage:"
  echo "  export GITHUB_TOKEN='your-new-token-here'"
  echo "  ./fix-runner-token.sh"
  echo ""
  echo "⚠️  Token must have these scopes:"
  echo "   - repo (Full control of private repositories)"
  echo "   - workflow (Update GitHub Action workflows)"
  echo "   - admin:org > manage_runners:org (Manage organization runners)"
  exit 1
fi

echo "🗑️  Deleting old token secret..."
kubectl delete secret github-token -n actions-runner-system --ignore-not-found=true

echo "🔐 Creating new token secret..."
kubectl create secret generic github-token \
  --from-literal=GITHUB_TOKEN="$GITHUB_TOKEN" \
  -n actions-runner-system

echo "🔄 Restarting runner controller..."
kubectl delete pods -l app.kubernetes.io/name=actions-runner-controller -n actions-runner-system

echo "⏳ Waiting for controller to restart..."
sleep 10

echo "🏃 Deleting old runners to force re-registration..."
kubectl delete runners --all -n actions-runner-system

echo "⏳ Waiting for new runners to be created..."
sleep 15

echo ""
echo "✅ Token updated!"
echo ""
echo "📊 Runner Status:"
kubectl get runners -n actions-runner-system
echo ""
echo "📋 Check logs:"
echo "  kubectl logs -l app.kubernetes.io/name=actions-runner-controller -n actions-runner-system"
echo ""
echo "🔍 Verify in GitHub:"
echo "  https://github.com/MorningMores/develop/settings/actions/runners"
