# Kubernetes Integration Testing Guide

This guide explains the comprehensive Kubernetes integration testing setup implemented for the Concert Platform project.

## Table of Contents

- [Overview](#overview)
- [CI/CD Pipeline](#cicd-pipeline)
- [Local Testing](#local-testing)
- [Test Coverage](#test-coverage)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

The K8s integration testing framework validates the entire Kubernetes deployment stack:

- **MySQL** StatefulSet with persistent storage
- **Backend** Spring Boot API (2 replicas)
- **Frontend** Nuxt 4 application (2 replicas)
- **Networking** Services, port-forwarding, and readiness checks
- **Application** Health checks, authentication, and API endpoints

### Why Integration Testing?

1. **Validates Real Deployment** - Tests actual K8s manifests, not mocked environments
2. **Catches Configuration Issues** - Environment variables, secrets, ConfigMaps
3. **Network Testing** - Service discovery, DNS, port exposure
4. **Database Initialization** - MySQL readiness, schema creation, data persistence
5. **Rolling Updates** - Deployment strategies, zero-downtime updates

## CI/CD Pipeline

### GitHub Actions Workflow

The pipeline is defined in `.github/workflows/k8s-deploy-with-tests.yml`:

```yaml
jobs:
  backend-tests      # Unit tests, JAR build
  frontend-tests     # Vitest unit tests
  build-images       # Docker images → GHCR
  k8s-integration-tests  # ← NEW! Kind cluster testing
  deploy-notification    # Status summary
```

### Integration Test Job

The `k8s-integration-tests` job:

1. **Creates Kind cluster** (Kubernetes in Docker)
2. **Pulls Docker images** from GHCR (just built)
3. **Loads images into Kind** cluster
4. **Deploys full stack** (MySQL, backend, frontend)
5. **Waits for readiness** (all pods healthy)
6. **Runs API tests** (registration, login, JWT auth)
7. **Generates report** (uploaded as artifact)
8. **Cleans up** (deletes Kind cluster)

### What Gets Tested?

#### Infrastructure Tests
- ✅ Namespace creation
- ✅ ConfigMap and Secrets applied
- ✅ PersistentVolumeClaim bound
- ✅ Services created with correct ports
- ✅ Deployments reach desired replica count
- ✅ Pods become healthy (readiness probes)

#### Application Tests
- ✅ MySQL accepts connections
- ✅ Backend health endpoint responds
- ✅ Frontend serves HTML
- ✅ User registration endpoint works
- ✅ User login returns JWT token
- ✅ Authenticated endpoint validates token

### Test Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  1. Create Kind Cluster (with port mappings)           │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  2. Pull Images from GHCR                               │
│     - concert-backend:SHA                               │
│     - concert-frontend:SHA                              │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  3. Load Images into Kind                               │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  4. Deploy K8s Stack                                    │
│     Namespace → ConfigMap → MySQL → Backend → Frontend │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  5. Wait for Readiness (kubectl wait)                   │
│     - MySQL StatefulSet ready                           │
│     - Backend Deployment available                      │
│     - Frontend Deployment available                     │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  6. Port Forwarding                                     │
│     - Backend: 8080                                     │
│     - Frontend: 3000                                    │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  7. Run API Integration Tests                           │
│     - GET /api/auth/test                                │
│     - POST /api/auth/register                           │
│     - POST /api/auth/login                              │
│     - GET /api/auth/test (with JWT)                     │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  8. Generate Test Report                                │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│  9. Cleanup (delete cluster)                            │
└─────────────────────────────────────────────────────────┘
```

## Local Testing

### Prerequisites

Install required tools:

```bash
# Install Kind
brew install kind

# Install kubectl (if not already installed)
brew install kubectl

# Verify Docker is running
docker ps
```

### Running Tests Locally

Use the provided script:

```bash
# Run full integration test suite
./k8s-integration-test.sh
```

The script will:
1. Create a local Kind cluster
2. Build Docker images
3. Deploy the full stack
4. Run integration tests
5. Generate a report
6. Keep services running for manual testing

### Manual Testing

After the script completes, access services:

```bash
# Frontend
curl http://localhost:3000

# Backend health check
curl http://localhost:8080/api/auth/test

# Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@test.com","password":"Test123!"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"john","password":"Test123!"}'
```

### Cleanup

```bash
# Delete Kind cluster
kind delete cluster --name concert-test-local

# Or press Ctrl+C if script is still running
```

## Test Coverage

### What's Tested in CI

#### ✅ Deployment Configuration
- Image references correct
- ImagePullPolicy appropriate
- Resource limits/requests
- Replica counts
- Rolling update strategy

#### ✅ Network Configuration
- Service ClusterIP assignments
- Port mappings correct
- Service selectors match pods
- Ingress rules (in NodePort mode for testing)

#### ✅ Storage Configuration
- PVC creation
- Volume mounts
- StatefulSet volumeClaimTemplates
- MySQL data persistence

#### ✅ Security Configuration
- Secrets properly referenced
- ConfigMaps applied
- Environment variables injected
- JWT token generation/validation

#### ✅ Application Health
- Liveness probes
- Readiness probes
- Startup probes
- Init containers

### What's NOT Tested (Yet)

#### ⚠️ Load Testing
- High concurrent user load
- Database connection pooling under stress
- Memory/CPU limits under load

#### ⚠️ Disaster Recovery
- Pod restarts
- Node failures
- Database backup/restore

#### ⚠️ Security Scanning
- Image vulnerability scanning
- Network policies
- RBAC configurations

#### ⚠️ Multi-Cluster
- Cross-cluster communication
- Multi-region deployments

## Test Results

### Viewing Test Reports

#### In GitHub Actions

1. Go to **Actions** tab
2. Click on workflow run
3. Scroll to **Artifacts** section
4. Download `k8s-integration-test-report`

Example report:

```markdown
# Kubernetes Integration Test Report

**Branch:** k8s-development
**Commit:** abc123def456
**Kubernetes Version:** v1.27.3

## Deployment Status
All deployments healthy ✅

## Test Results Summary
- ✅ MySQL StatefulSet deployed and ready
- ✅ Backend Deployment scaled to 2 replicas
- ✅ Frontend Deployment scaled to 2 replicas
- ✅ All pods running and healthy
- ✅ Backend API responding to health checks
- ✅ User registration endpoint functional
- ✅ User login endpoint functional
- ✅ JWT authentication working
```

#### Locally

After running `./k8s-integration-test.sh`, view:

```bash
cat k8s-integration-test-report.md
```

### PR Comments

For pull requests, the workflow automatically comments:

```
## ✅ K8s Integration Tests Passed!

**Docker Images Built:**
- Backend: ghcr.io/morningmores/develop/concert-backend:abc123
- Frontend: ghcr.io/morningmores/develop/concert-frontend:abc123

**Integration Tests:** All passed ✅
- MySQL deployment and readiness
- Backend API health checks
- Frontend serving content
- User registration and authentication
- JWT token generation and validation

**Ready for deployment!**
```

## Troubleshooting

### Common Issues

#### 1. Kind Cluster Creation Failed

```
ERROR: failed to create cluster: ...
```

**Solutions:**
- Ensure Docker Desktop is running
- Check available disk space (need ~5GB)
- Try deleting existing cluster: `kind delete cluster --name concert-test`

#### 2. Images Failed to Load

```
ERROR: failed to load image into cluster
```

**Solutions:**
- Check Docker images exist: `docker images | grep concert`
- Verify image names match manifests
- Try manual load: `kind load docker-image <image> --name concert-test`

#### 3. MySQL Not Ready

```
error: timed out waiting for the condition on pods
```

**Solutions:**
- Check MySQL logs: `kubectl logs -l app=mysql -n concert-platform`
- Verify PVC bound: `kubectl get pvc -n concert-platform`
- Check storage class: `kubectl get storageclass`
- Increase timeout in manifests

#### 4. Backend/Frontend Not Responding

```
Backend failed to respond after 30 attempts
```

**Solutions:**
- Check pod status: `kubectl get pods -n concert-platform`
- View logs: `kubectl logs -l app=backend -n concert-platform`
- Check ConfigMap/Secrets: `kubectl get configmap,secret -n concert-platform`
- Verify environment variables
- Check database connection string

#### 5. Port Forwarding Issues

```
Unable to listen on port 8080
```

**Solutions:**
- Check if port already in use: `lsof -i :8080`
- Kill conflicting process: `kill -9 <PID>`
- Use different port: `kubectl port-forward ... 8081:8080`

### Debug Commands

```bash
# Check all resources
kubectl get all -n concert-platform

# Describe pod (shows events)
kubectl describe pod <pod-name> -n concert-platform

# View logs
kubectl logs <pod-name> -n concert-platform
kubectl logs <pod-name> -n concert-platform --previous  # Previous container

# Exec into pod
kubectl exec -it <pod-name> -n concert-platform -- /bin/bash

# Check events
kubectl get events -n concert-platform --sort-by='.lastTimestamp'

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mysql-service.concert-platform.svc.cluster.local

# Test MySQL connection
kubectl run -it --rm mysql-client --image=mysql:8.0 --restart=Never -- mysql -h mysql-service.concert-platform.svc.cluster.local -u concertuser -p
```

## Best Practices

### 1. Keep Tests Fast
- Use smaller images when possible
- Cache build artifacts
- Parallel test execution where safe

### 2. Make Tests Idempotent
- Use unique usernames (timestamps)
- Clean up test data
- Don't depend on execution order

### 3. Test Real Scenarios
- Use production-like configurations
- Test with realistic data
- Include error cases

### 4. Monitor Resource Usage
```bash
# Check resource consumption
kubectl top nodes
kubectl top pods -n concert-platform
```

### 5. Keep Manifests DRY
- Use Kustomize or Helm for variants
- Template environment-specific values
- Version control all configs

### 6. Document Expected Behavior
- Add comments to manifests
- Document why specific values chosen
- Track configuration decisions

## Integration with Existing Workflows

### Backend Testing

The K8s tests complement existing backend tests:

```
Unit Tests (Maven)
  ↓
Integration Tests (Testcontainers)
  ↓
Build JAR
  ↓
Build Docker Image
  ↓
K8s Integration Tests ← You are here
  ↓
Deploy to Local/Staging/Production
```

### Frontend Testing

Frontend testing flow:

```
Unit Tests (Vitest)
  ↓
Component Tests
  ↓
Build Production Bundle
  ↓
Build Docker Image
  ↓
K8s Integration Tests ← You are here
  ↓
Deploy
```

## Future Enhancements

### Planned Improvements

1. **Load Testing** - Add k6 or Locust tests
2. **Security Scanning** - Trivy for image vulnerabilities
3. **E2E Tests** - Playwright/Cypress browser tests
4. **Performance Monitoring** - Prometheus metrics collection
5. **Chaos Engineering** - Pod deletion, network delays
6. **Multi-Environment** - Test staging/production configs

### How to Contribute

To add new tests:

1. Add test logic to workflow file
2. Update test script for local execution
3. Document expected behavior
4. Update this guide

## Related Documentation

- [K8s Deployment Guide](./K8S_DEPLOYMENT_GUIDE_K8S_DEV_BRANCH.md)
- [Three Layer Testing Guide](../THREE_LAYER_TESTING_GUIDE.md)
- [CI/CD Setup](./CI_CD_SETUP.md)
- [Testing Strategy](../TESTING_STRATEGY.md)

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review test logs and reports
3. Open GitHub issue with full error output
4. Include output from debug commands

---

**Last Updated:** October 18, 2025  
**Maintained By:** DevOps Team
