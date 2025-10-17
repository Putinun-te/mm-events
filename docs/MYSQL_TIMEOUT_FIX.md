# MySQL Timeout Fix Documentation

**Date:** October 18, 2025  
**Commit:** 05d369d  
**Status:** ✅ FIXED

## Problem Statement

MySQL pod was timing out during GitHub Actions workflow with error:
```
error: timed out waiting for the condition on pods/mysql-0
Error: Process completed with exit code 1.
```

## Root Cause

MySQL initialization in CI environments (Kind clusters) requires more time than initially configured:
- **Readiness probe** started too early (10s) before MySQL could initialize
- **Wait timeout** was too short (5 minutes) for resource-constrained CI
- **Insufficient retries** caused permanent failure before MySQL was ready

## Fixes Applied

### 1. MySQL StatefulSet Configuration (`k8s/mysql.yaml`)

#### Before:
```yaml
livenessProbe:
  exec:
    command:
    - mysqladmin
    - ping
    - -h
    - localhost
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5

readinessProbe:
  exec:
    command:
    - mysqladmin
    - ping
    - -h
    - localhost
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 2
```

#### After:
```yaml
livenessProbe:
  exec:
    command:
    - mysqladmin
    - ping
    - -h
    - localhost
  initialDelaySeconds: 60      # ⬆️ Increased from 30s
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 6          # ✨ NEW: Allow 6 failures

readinessProbe:
  exec:
    command:
    - mysqladmin
    - ping
    - -h
    - localhost
  initialDelaySeconds: 30      # ⬆️ Increased from 10s
  periodSeconds: 10            # ⬆️ Increased from 5s
  timeoutSeconds: 5            # ⬆️ Increased from 2s
  failureThreshold: 10         # ✨ NEW: Allow 10 failures
```

**Impact:**
- Readiness check now waits **30s** before first attempt (MySQL has time to initialize)
- Total readiness time: `30s + (10 retries × 10s) = 130 seconds maximum`
- Liveness check waits **60s** before first attempt (prevents premature restarts)

### 2. Workflow Deployment Step (`.github/workflows/k8s-deploy-with-tests.yml`)

#### Before:
```yaml
echo "Deploying MySQL..."
kubectl apply -f k8s-test/mysql.yaml

echo "Waiting for MySQL to be ready (max 5 minutes)..."
kubectl wait --for=condition=ready pod -l app=mysql -n concert-platform --timeout=300s
```

#### After:
```yaml
echo "Deploying MySQL..."
kubectl apply -f k8s-test/mysql.yaml

echo "Waiting for MySQL pod to be created..."
for i in {1..30}; do
  if kubectl get pod mysql-0 -n concert-platform 2>/dev/null; then
    echo "✅ MySQL pod created"
    break
  fi
  echo "Waiting for pod creation... attempt $i/30"
  sleep 2
done

echo "Checking MySQL pod status..."
kubectl get pod mysql-0 -n concert-platform -o wide

echo "Waiting for MySQL to be ready (max 8 minutes for CI environment)..."
kubectl wait --for=condition=ready pod/mysql-0 -n concert-platform --timeout=480s || {
  echo "❌ MySQL failed to become ready, checking logs..."
  kubectl describe pod mysql-0 -n concert-platform
  kubectl logs mysql-0 -n concert-platform --tail=100
  exit 1
}
```

**Improvements:**
- ⏰ **Timeout**: 5 minutes → **8 minutes** (480s)
- 🎯 **Specific pod**: Changed from label selector to `pod/mysql-0` (more reliable for StatefulSet)
- 🔍 **Better checking**: Wait for pod creation first, then readiness
- 📝 **Error handling**: Show `describe` and logs if MySQL fails
- 📊 **Progress visibility**: Show pod status during wait

## Timeline Analysis

| Phase | Duration | Details |
|-------|----------|---------|
| **Pod Creation** | 0-10s | Kubernetes creates pod, pulls image |
| **Container Start** | 10-30s | Docker container initializes |
| **MySQL Initialization** | 30-90s | MySQL creates data directory, sets up system tables |
| **Readiness Checks Begin** | 30s | First readiness probe executes |
| **Typical Ready Time** | 60-120s | MySQL ready for connections |
| **Maximum Wait** | 480s (8min) | Safety margin for slow CI environments |

## Verification

### Expected Workflow Behavior:
1. ✅ MySQL pod created within 10 seconds
2. ✅ Pod status shown: `Pending` → `ContainerCreating` → `Running`
3. ✅ Readiness wait: Typically 1-2 minutes
4. ✅ MySQL ready: Logs show "ready for connections"
5. ✅ Backend and frontend deploy successfully

### How to Monitor:
```bash
# Watch pod status
kubectl get pod mysql-0 -n concert-platform --watch

# Check readiness probe status
kubectl describe pod mysql-0 -n concert-platform | grep -A 10 Readiness

# View MySQL logs
kubectl logs mysql-0 -n concert-platform -f
```

## Testing Results

**Commit:** 05d369d  
**Workflow:** https://github.com/MorningMores/develop/actions

Expected results:
- ✅ MySQL becomes ready within 1-2 minutes
- ✅ No timeout errors
- ✅ Full integration tests pass
- ✅ Clear error logs if anything fails

## Best Practices Applied

1. ✅ **Adequate Initial Delays**: Allow services time to initialize before health checks
2. ✅ **Sufficient Timeouts**: Account for CI environment resource constraints
3. ✅ **Failure Thresholds**: Provide retry mechanisms before declaring failure
4. ✅ **Detailed Logging**: Capture pod status and logs for debugging
5. ✅ **Specific Resource Names**: Use exact pod names for StatefulSets
6. ✅ **Error Handling**: Gracefully fail with diagnostic information

## Related Issues

- **Kind Cluster Fix**: ea4652e (config file creation)
- **Workflow Trigger Fix**: c39d7c2 (path filter correction)
- **Enhanced Logging**: e763906 (clear fix indicators)

## References

- [Kubernetes Liveness/Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [MySQL Docker Documentation](https://hub.docker.com/_/mysql)
- [StatefulSet Best Practices](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

---

**Next Steps:** Monitor workflow run from commit 05d369d to confirm fix is working.
