# Kubernetes Deployment Guide (k8s-development branch)

## Overview
This branch (`k8s-development`) contains production-ready Kubernetes deployment configuration and automated CI/CD pipeline for deploying the Concert Platform to Kubernetes clusters.

## Branch Strategy
- **main**: Stable, tested code
- **k8s-development**: K8s-specific deployments and CI/CD
- Uses all files from `main` + adds K8s-specific manifests

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Ingress (LoadBalancer / NodePort)            │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                       │
│     ┌───────────────┴────────────────┐                     │
│     │                                │                     │
│  ┌──▼───────────────┐      ┌────────▼──────────┐          │
│  │ Frontend Pod(s)  │      │ Backend Pod(s)    │          │
│  │ (Nuxt 4, 2x)     │      │ (Spring Boot, 2x) │          │
│  └──────────────────┘      └────┬───────────────┘          │
│                                  │                          │
│                         ┌────────▼──────────┐              │
│                         │  MySQL Service    │              │
│                         │  (Stateful)       │              │
│                         └───────────────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Files Overview

### K8s Manifests (`k8s/`)
- `namespace.yaml` - Creates `concert-platform` namespace
- `configmap.yaml` - Environment configuration (URLs, profiles)
- `mysql.yaml` - MySQL StatefulSet + Service + PVC
- `backend.yaml` - Backend Deployment + Service (2 replicas)
- `frontend.yaml` - Frontend Deployment + Service (2 replicas)
- `ingress.yaml` - Ingress for external access

### CI/CD Pipeline (`.github/workflows/k8s-deploy.yml`)
1. **Backend Tests & Build** - Maven tests, build JAR
2. **Frontend Tests & Build** - Vitest, build Nuxt output
3. **Build Docker Images** - Push to ghcr.io registry
4. **Deploy to K8s** - Apply manifests, verify rollout

## Prerequisites

### Local Setup
```bash
# 1. Ensure kubectl is installed
kubectl version --client

# 2. Have kubeconfig configured
export KUBECONFIG=~/.kube/config

# 3. Test cluster access
kubectl cluster-info
```

### GitHub Secrets Required
```
KUBE_CONFIG          # Base64 encoded kubeconfig file
```

To create:
```bash
cat ~/.kube/config | base64 | pbcopy  # macOS
cat ~/.kube/config | base64 | xclip   # Linux
```

Set in GitHub: Settings → Secrets and variables → Actions

## Deployment Steps

### Manual Deployment
```bash
# 1. Switch to k8s-development branch
git checkout k8s-development

# 2. Update image references in manifests if needed
vim k8s/backend.yaml k8s/frontend.yaml

# 3. Create namespace
kubectl apply -f k8s/namespace.yaml

# 4. Create ConfigMap and Secrets
kubectl apply -f k8s/configmap.yaml
# Note: Update secrets externally or use sealed-secrets

# 5. Deploy MySQL first
kubectl apply -f k8s/mysql.yaml
kubectl wait --for=condition=ready pod -l app=mysql -n concert-platform --timeout=300s

# 6. Deploy backend
kubectl apply -f k8s/backend.yaml
kubectl rollout status deployment/backend -n concert-platform

# 7. Deploy frontend
kubectl apply -f k8s/frontend.yaml
kubectl rollout status deployment/frontend -n concert-platform

# 8. Apply ingress
kubectl apply -f k8s/ingress.yaml

# 9. Verify deployment
kubectl get all -n concert-platform
```

### Automated Deployment (CI/CD)
```bash
# Push to k8s-development triggers automatic deployment
git push origin k8s-development

# Monitor in GitHub Actions
# Settings → Actions → K8s Deployment Pipeline
```

## Configuration

### Environment Variables (configmap.yaml)
```yaml
SPRING_DATASOURCE_URL: jdbc:mysql://mysql-service:3306/concert_db
SPRING_DATASOURCE_USERNAME: concert_user
SPRING_JPA_HIBERNATE_DDL_AUTO: validate
SPRING_PROFILES_ACTIVE: k8s
```

### Secrets (External Management)
```bash
# Create secrets manually
kubectl create secret generic concert-secrets \
  -n concert-platform \
  --from-literal=SPRING_DATASOURCE_PASSWORD=<your-password>
```

## Monitoring & Debugging

### Check Deployment Status
```bash
# Deployments
kubectl get deployments -n concert-platform
kubectl describe deployment backend -n concert-platform

# Pods
kubectl get pods -n concert-platform
kubectl logs -n concert-platform -l app=backend --tail=100

# Services
kubectl get svc -n concert-platform

# Ingress
kubectl get ingress -n concert-platform
```

### View Logs
```bash
# Backend logs
kubectl logs -n concert-platform -f deployment/backend

# Frontend logs
kubectl logs -n concert-platform -f deployment/frontend

# MySQL logs
kubectl logs -n concert-platform -f statefulset/mysql
```

### Debug Pod
```bash
kubectl exec -it -n concert-platform <pod-name> -- /bin/bash
```

## Scaling

### Horizontal Pod Autoscaling (Optional)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: concert-platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Manual Scaling
```bash
kubectl scale deployment backend -n concert-platform --replicas=5
```

## Rollback

### Automatic Rollback on Failure
```bash
kubectl rollout undo deployment/backend -n concert-platform
```

### View Rollout History
```bash
kubectl rollout history deployment/backend -n concert-platform
```

## Cleanup

```bash
# Delete everything in namespace
kubectl delete namespace concert-platform

# Or selective cleanup
kubectl delete deployment backend -n concert-platform
kubectl delete deployment frontend -n concert-platform
kubectl delete statefulset mysql -n concert-platform
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n concert-platform
kubectl logs <pod-name> -n concert-platform
```

### Image pull errors
```bash
# Check image registry credentials
kubectl get secrets -n concert-platform
kubectl describe imagepullsecrets -n concert-platform
```

### Database connection issues
```bash
# Test MySQL connectivity
kubectl run -it --rm debug --image=mysql:8.0 --restart=Never -n concert-platform -- \
  mysql -h mysql-service -u concert_user -p -e "SELECT VERSION();"
```

### Service discovery
```bash
# DNS test from pod
kubectl exec -it -n concert-platform <backend-pod> -- nslookup mysql-service
```

## CI/CD Pipeline Details

### Stages
1. **Test** - Run unit tests
2. **Build** - Compile and package applications
3. **Docker** - Build and push container images
4. **Deploy** - Apply K8s manifests
5. **Verify** - Check deployment status

### Environment Variables
- `REGISTRY`: ghcr.io
- `BACKEND_IMAGE_NAME`: {repo}/concert-backend
- `FRONTEND_IMAGE_NAME`: {repo}/concert-frontend

### Artifacts
- Backend JAR
- Frontend .output/
- Deployment report

## Best Practices

1. **Always use resource limits** - Prevents pod eviction
2. **Use health checks** - Liveness and readiness probes configured
3. **Initialize containers** - Wait for dependencies (MySQL)
4. **Rolling updates** - Zero-downtime deployments
5. **ConfigMaps & Secrets** - Keep sensitive data external
6. **Monitoring** - Use kubectl logs and events
7. **Backup strategy** - PVC snapshots for databases

## Next Steps

1. Set up KUBE_CONFIG secret in GitHub
2. Configure domain in ingress.yaml
3. Set up persistent storage for MySQL
4. Configure resource quotas per namespace
5. Implement Prometheus monitoring
6. Set up log aggregation (ELK/Loki)
