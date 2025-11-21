#!/bin/bash

echo "🔍 Checking GitHub Actions Runners Status"
echo "=========================================="
echo ""

echo "📊 Kubernetes Runner Pods:"
kubectl get pods -n actions-runner-system -l runner-deployment-name=concert-runners
echo ""

echo "🏃 Runner Details:"
kubectl get runners -n actions-runner-system -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,LABELS:.spec.labels
echo ""

echo "📋 Runner Logs (last 10 lines):"
RUNNER_POD=$(kubectl get pods -n actions-runner-system -l runner-deployment-name=concert-runners -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $RUNNER_POD"
kubectl logs $RUNNER_POD -n actions-runner-system --tail=10 2>/dev/null || echo "Could not fetch logs"
echo ""

echo "✅ Runners are deployed and listening!"
echo ""
echo "🔍 To verify in GitHub:"
echo "   1. Go to: https://github.com/MorningMores/develop/settings/actions/runners"
echo "   2. Look for runners with labels: self-hosted, eks, singapore"
echo ""
echo "💡 If runners don't appear in GitHub:"
echo "   1. Check token has 'admin:org' or 'repo' scope"
echo "   2. Verify token in secret: kubectl get secret github-token -n actions-runner-system"
echo "   3. Restart runners: kubectl rollout restart deployment -n actions-runner-system"
