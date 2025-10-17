# PVC Storage Class Fix for Kind Clusters

**Date:** October 18, 2025  
**Commit:** 7c99bce  
**Status:** ✅ CRITICAL FIX

## Problem Statement

MySQL pod failed to schedule with error:
```
Warning  FailedScheduling  default-scheduler  
0/1 nodes are available: pod has unbound immediate PersistentVolumeClaims. 
preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
```

Pod status showed:
```
Status:           Pending
Node:             <none>
Conditions:
  Type           Status
  PodScheduled   False
```

## Root Cause

**Storage class mismatch between local and CI environments:**

| Environment | Storage Class | Provisioner |
|-------------|---------------|-------------|
| **Docker Desktop** (local) | `hostpath` | docker.io/hostpath |
| **Kind** (CI) | `standard` | rancher.io/local-path |

The `k8s/mysql.yaml` manifest was configured for Docker Desktop:
```yaml
storageClassName: hostpath  # ❌ Doesn't exist in Kind!
```

Kind clusters don't have `hostpath` storage class, so the PVC remained unbound, preventing pod scheduling.

## The Fix

### 1. Updated Workflow to Replace Storage Class

**File:** `.github/workflows/k8s-deploy-with-tests.yml`

```yaml
- name: 🔧 Create test K8s manifests
  run: |
    # Copy base manifests
    cp k8s/*.yaml k8s-test/
    
    # Fix storageClassName for Kind (uses 'standard', not 'hostpath')
    sed -i "s|storageClassName: hostpath|storageClassName: standard|g" k8s-test/mysql.yaml
```

This dynamically replaces the storage class name when deploying to Kind, allowing the same manifests to work in both environments.

### 2. Added PVC Verification Step

```yaml
- name: 🚀 Deploy to Kind cluster
  run: |
    echo "Checking storage classes..."
    kubectl get storageclass
    
    echo "Deploying MySQL..."
    kubectl apply -f k8s-test/mysql.yaml
    
    echo "Checking PVC status..."
    kubectl get pvc -n concert-platform
    kubectl describe pvc mysql-pvc -n concert-platform
    
    echo "Waiting for PVC to be bound (max 2 minutes)..."
    kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/mysql-pvc -n concert-platform --timeout=120s || {
      echo "❌ PVC failed to bind, checking details..."
      kubectl get pvc mysql-pvc -n concert-platform -o yaml
      kubectl get pv
      exit 1
    }
    
    echo "✅ PVC bound successfully"
```

### 3. Benefits

✅ **Verify storage classes exist** before deployment  
✅ **Wait for PVC binding** before creating pods  
✅ **Show detailed diagnostics** if PVC fails to bind  
✅ **Support multiple environments** (Docker Desktop + Kind)  
✅ **Clear error messages** for troubleshooting

## Storage Classes Comparison

### Kind (CI Environment)
```bash
$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY
standard (default)   rancher.io/local-path   Delete
```

### Docker Desktop (Local)
```bash
$ kubectl get storageclass
NAME                 PROVISIONER          RECLAIMPOLICY
hostpath (default)   docker.io/hostpath   Delete
```

## Verification Steps

### Check Storage Classes
```bash
kubectl get storageclass
```

### Check PVC Status
```bash
kubectl get pvc -n concert-platform
kubectl describe pvc mysql-pvc -n concert-platform
```

### Check PV Status
```bash
kubectl get pv
```

### Check Pod Scheduling
```bash
kubectl describe pod mysql-0 -n concert-platform
```

## Expected Workflow Behavior

1. ✅ **Display storage classes** - Shows `standard` is available
2. ✅ **Deploy MySQL manifest** - Creates PVC with `standard` storageClass
3. ✅ **PVC binds immediately** - Kind's dynamic provisioner creates PV
4. ✅ **MySQL pod scheduled** - Pod can now mount the bound PVC
5. ✅ **MySQL pod starts** - Container runs successfully
6. ✅ **Readiness checks pass** - Pod becomes ready within 1-2 minutes

## Timeline of PVC Binding

| Time | Event | Details |
|------|-------|---------|
| 0s | PVC created | `kubectl apply -f mysql.yaml` |
| 1-2s | PV provisioned | Kind's `local-path` provisioner creates PV |
| 2-3s | PVC bound | PVC status changes to `Bound` |
| 3-5s | Pod scheduled | Kubernetes scheduler assigns pod to node |
| 5-10s | Container starts | MySQL container begins initialization |
| 30-120s | Pod ready | MySQL completes startup, readiness probe passes |

## Alternative Solutions

### Option 1: Use Standard Storage Class in Base Manifest
**Not recommended** - Would break Docker Desktop deployments

```yaml
storageClassName: standard  # ❌ Doesn't work on Docker Desktop
```

### Option 2: Dynamic Provisioner Detection
**Too complex** - Requires cluster-specific logic

### Option 3: Separate Manifests per Environment
**Maintenance burden** - Would need duplicate files

### ✅ Option 4: Runtime Replacement (Chosen)
**Best approach** - One set of manifests, environment-specific adjustments via `sed`

## Related Issues

- **MySQL Timeout Fix**: 05d369d (probe delays, failure thresholds)
- **Kind Cluster Fix**: ea4652e (config file creation)
- **Workflow Trigger Fix**: c39d7c2 (path filter correction)

## Testing Results

**Commit:** 7c99bce  
**Expected Results:**
- ✅ Storage class verification passes
- ✅ PVC binds within 2-3 seconds
- ✅ MySQL pod schedules immediately
- ✅ Complete workflow passes

## References

- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Kind Local Path Provisioner](https://github.com/kubernetes-sigs/kind/issues/1487)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

---

**Next Steps:** Monitor workflow run from commit 7c99bce to verify PVC binds successfully.
