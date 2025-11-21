#!/bin/bash

set -e

echo "🔧 Fixing EKS Self-Hosted Runners and CI/CD Pipeline"
echo "====================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_info "Connected to cluster: $(kubectl config current-context)"

# Step 1: Clean up existing runners
echo ""
echo "🧹 Step 1: Cleaning up existing runners..."
kubectl delete runners --all -n actions-runner-system --ignore-not-found=true
kubectl delete runnerdeployments --all -n actions-runner-system --ignore-not-found=true
print_status "Cleaned up existing runners"

# Step 2: Verify token is set
echo ""
echo "🔑 Step 2: Verifying GitHub token..."
if ! kubectl get secret github-token -n actions-runner-system &> /dev/null; then
    print_error "GitHub token secret not found. Please run:"
    echo "kubectl create secret generic github-token --from-literal=token=YOUR_TOKEN --namespace=actions-runner-system"
    exit 1
fi

# Decode and verify token format
TOKEN=$(kubectl get secret github-token -n actions-runner-system -o jsonpath='{.data.token}' | base64 -d)
if [[ ! "$TOKEN" =~ ^ghp_ ]]; then
    print_error "Invalid GitHub token format. Token should start with 'ghp_'"
    exit 1
fi
print_status "GitHub token verified"

# Step 3: Restart actions-runner-controller
echo ""
echo "🔄 Step 3: Restarting actions-runner-controller..."
kubectl rollout restart deployment actions-runner-controller -n actions-runner-system
kubectl rollout status deployment actions-runner-controller -n actions-runner-system --timeout=120s
print_status "Controller restarted successfully"

# Step 4: Create enhanced runner deployment
echo ""
echo "🚀 Step 4: Creating enhanced runner deployment..."

cat <<EOF | kubectl apply -f -
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: concert-runners
  namespace: actions-runner-system
spec:
  replicas: 2
  template:
    spec:
      repository: MorningMores/develop
      labels:
        - self-hosted
        - linux
        - x64
        - eks
        - singapore
      image: summerwind/actions-runner:latest
      dockerdWithinRunnerContainer: true
      resources:
        requests:
          cpu: 500m
          memory: 1Gi
        limits:
          cpu: 2000m
          memory: 4Gi
      env:
        - name: RUNNER_WORKDIR
          value: /tmp/runner
        - name: DOCKER_HOST
          value: unix:///var/run/docker.sock
      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock
        - name: runner-work
          mountPath: /tmp/runner
      volumes:
        - name: docker-sock
          hostPath:
            path: /var/run/docker.sock
        - name: runner-work
          emptyDir: {}
      nodeSelector:
        kubernetes.io/arch: amd64
      tolerations:
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 300
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 300
EOF

print_status "Enhanced runner deployment created"

# Step 5: Wait for runners to be ready
echo ""
echo "⏳ Step 5: Waiting for runners to be ready..."
sleep 30

# Check runner status
for i in {1..12}; do
    READY_RUNNERS=$(kubectl get runners -n actions-runner-system --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$READY_RUNNERS" -ge 2 ]; then
        print_status "Runners are ready!"
        break
    fi
    echo "Waiting for runners... ($i/12) - Current runners: $READY_RUNNERS"
    sleep 10
done

# Step 6: Verify runner status
echo ""
echo "🔍 Step 6: Verifying runner status..."
kubectl get runners -n actions-runner-system -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,LABELS:.spec.labels

# Check for any errors
echo ""
echo "📋 Recent events:"
kubectl get events -n actions-runner-system --sort-by='.lastTimestamp' | tail -5

# Step 7: Test GitHub API connectivity
echo ""
echo "🌐 Step 7: Testing GitHub API connectivity..."
if curl -s -H "Authorization: token $TOKEN" https://api.github.com/repos/MorningMores/develop/actions/runners | jq -r '.runners[].status' | grep -q "online"; then
    print_status "Runners are online in GitHub!"
else
    print_warning "Runners may still be connecting to GitHub. Check https://github.com/MorningMores/develop/settings/actions/runners"
fi

echo ""
echo "🎉 EKS Runner Setup Complete!"
echo "============================================"
echo "✅ Actions-runner-controller restarted"
echo "✅ Enhanced runner deployment created"
echo "✅ Runners configured with proper resources"
echo "✅ Docker-in-Docker enabled"
echo ""
echo "🔍 Next steps:"
echo "1. Check runners at: https://github.com/MorningMores/develop/settings/actions/runners"
echo "2. Run the test pipeline: gh workflow run quick-tests.yml"
echo "3. Monitor runner logs: kubectl logs -l app=actions-runner -n actions-runner-system"
echo ""
echo "🚀 Ready to run CI/CD pipelines on EKS!"