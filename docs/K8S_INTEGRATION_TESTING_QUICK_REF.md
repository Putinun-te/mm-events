# K8s Integration Testing - Quick Reference

## 🚀 Quick Start

### Run Tests Locally
```bash
./k8s-integration-test.sh
```

### Run in CI/CD
Push to `k8s-development` branch - tests run automatically!

## 📋 What Gets Tested

| Component | Tests |
|-----------|-------|
| **MySQL** | ✅ StatefulSet deployed<br>✅ Pod ready<br>✅ PVC bound<br>✅ Accepts connections |
| **Backend** | ✅ Deployment scaled<br>✅ Pods healthy<br>✅ API responds<br>✅ JWT auth works |
| **Frontend** | ✅ Deployment scaled<br>✅ Pods healthy<br>✅ Serves content |
| **Network** | ✅ Services created<br>✅ Port forwarding<br>✅ Service discovery |

## 🔧 Prerequisites

```bash
# Install Kind
brew install kind

# Install kubectl
brew install kubectl

# Verify Docker
docker ps
```

## 📊 View Test Results

### GitHub Actions
```
1. Actions tab → Latest workflow run
2. Download artifact: "k8s-integration-test-report"
```

### Local
```bash
cat k8s-integration-test-report.md
```

## 🧪 Test Endpoints Manually

```bash
# Health check
curl http://localhost:8080/api/auth/test

# Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"Test123!"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"Test123!"}'
```

## 🐛 Debug Commands

```bash
# Check all resources
kubectl get all -n concert-platform

# Pod logs
kubectl logs -l app=backend -n concert-platform

# Pod events
kubectl describe pod <pod-name> -n concert-platform

# Exec into pod
kubectl exec -it <pod-name> -n concert-platform -- /bin/bash

# Port forward
kubectl port-forward -n concert-platform svc/backend-service 8080:8080
```

## 🧹 Cleanup

```bash
# Delete test cluster
kind delete cluster --name concert-test-local

# Or use cleanup script
./k8s/cleanup.sh
```

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| Kind cluster fails | Check Docker running, free disk space |
| Images won't load | Verify images built: `docker images \| grep concert` |
| MySQL timeout | Check logs: `kubectl logs -l app=mysql -n concert-platform` |
| Backend not responding | Check logs and env vars: `kubectl describe pod -l app=backend -n concert-platform` |
| Port already in use | Kill process: `lsof -i :8080` then `kill -9 <PID>` |

## 📚 Full Documentation

See [K8S_INTEGRATION_TESTING.md](./K8S_INTEGRATION_TESTING.md) for complete guide.

## 🎯 CI/CD Pipeline

```
backend-tests
frontend-tests
    ↓
build-images (GHCR)
    ↓
k8s-integration-tests ← NEW!
    ↓
deploy-notification
```

## ✅ Success Criteria

All tests pass when:
- ✅ All pods reach `Running` state
- ✅ All deployments are `Available`
- ✅ Backend health endpoint returns 200
- ✅ Frontend serves HTML
- ✅ User can register and login
- ✅ JWT token is valid

## 🔄 Test Flow

```
1. Create Kind cluster
2. Load Docker images
3. Deploy K8s stack
4. Wait for readiness
5. Run API tests
6. Generate report
7. Cleanup
```

## 💡 Tips

- Run locally before pushing to catch issues early
- Check test reports for detailed deployment status
- Use debug commands to investigate failures
- Keep test data unique (use timestamps)
- Monitor resource usage with `kubectl top`

## 🚨 Common Fixes

```bash
# Reset everything
kind delete cluster --name concert-test-local
docker system prune -f
./k8s-integration-test.sh

# Check resource limits
kubectl describe node

# View all events
kubectl get events -n concert-platform --sort-by='.lastTimestamp'
```

---

**Quick Links:**
- [Full Testing Guide](./K8S_INTEGRATION_TESTING.md)
- [K8s Deployment Guide](./K8S_DEPLOYMENT_GUIDE_K8S_DEV_BRANCH.md)
- [Workflow File](../.github/workflows/k8s-deploy-with-tests.yml)
