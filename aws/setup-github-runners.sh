#!/bin/bash

set -e

NAMESPACE="actions-runner-system"
GITHUB_ORG="MorningMores"
REPO="develop"

echo "🏃 Setting up GitHub Actions self-hosted runners on EKS..."

# Install cert-manager (required)
echo "📦 Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

echo "⏳ Waiting for cert-manager..."
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager-webhook -n cert-manager

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Get GitHub PAT
echo ""
echo "⚠️  Create GitHub Personal Access Token:"
echo "   1. Go to: https://github.com/settings/tokens/new"
echo "   2. Select: repo (full control)"
echo "   3. Generate token and paste below:"
echo ""
read -sp "GitHub PAT: " GITHUB_TOKEN
echo ""

# Clean up existing installation
echo "🧹 Cleaning up existing installation..."
helm uninstall actions-runner-controller -n $NAMESPACE 2>/dev/null || true
kubectl delete crd runnerdeployments.actions.summerwind.dev 2>/dev/null || true
kubectl delete crd runnerreplicasets.actions.summerwind.dev 2>/dev/null || true
kubectl delete crd runners.actions.summerwind.dev 2>/dev/null || true
kubectl delete crd runnersets.actions.summerwind.dev 2>/dev/null || true
kubectl delete crd horizontalrunnerautoscalers.actions.summerwind.dev 2>/dev/null || true
sleep 5

# Install Actions Runner Controller via Helm
echo "📦 Installing Actions Runner Controller via Helm..."
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

helm install actions-runner-controller \
  actions-runner-controller/actions-runner-controller \
  --namespace $NAMESPACE \
  --set authSecret.github_token=$GITHUB_TOKEN \
  --wait

# Create runner deployment
cat <<EOF | kubectl apply -f -
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: concert-runners
  namespace: $NAMESPACE
spec:
  replicas: 2
  template:
    spec:
      repository: $GITHUB_ORG/$REPO
      labels:
        - self-hosted
        - eks
        - singapore
EOF

echo "✅ GitHub Actions runners deployed!"
echo ""
echo "📋 Check status:"
echo "kubectl get runners -n $NAMESPACE"
echo ""
echo "🔧 Use in workflow:"
echo "runs-on: [self-hosted, eks, singapore]"
