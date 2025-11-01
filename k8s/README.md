# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the MM Concerts platform.

## Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured
- Helm (optional, for advanced configurations)
- NGINX Ingress Controller (for ingress)

## Quick Start

### 1. Create Namespace and Resources

```bash
# Apply all configurations in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/mysql.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress.yaml
```

### 2. Verify Deployment

```bash
# Check all resources
kubectl get all -n concert-platform

# Check pods status
kubectl get pods -n concert-platform

# Check services
kubectl get svc -n concert-platform

# Check ingress
kubectl get ingress -n concert-platform
```

### 3. Access the Application

```bash
# Get frontend service external IP
kubectl get svc frontend-service -n concert-platform

# Get ingress address
kubectl get ingress concert-ingress -n concert-platform
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Ingress                          │
│            (concert.example.com)                    │
└─────────────────┬───────────────────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
    ┌────▼─────┐     ┌────▼────┐
    │ Frontend │     │ Backend │
    │ Service  │     │ Service │
    │  (80)    │     │ (8080)  │
    └────┬─────┘     └────┬────┘
         │                │
    ┌────▼─────┐     ┌────▼────┐
    │ Frontend │     │ Backend │
    │   Pods   │     │  Pods   │
    │  (2-5)   │     │  (2-5)  │
    └──────────┘     └────┬────┘
                          │
                     ┌────▼────┐
                     │  MySQL  │
                     │ Service │
                     │ (3306)  │
                     └────┬────┘
                          │
                     ┌────▼────┐
                     │  MySQL  │
                     │StatefulSet
                     └─────────┘
```

## Components

### 1. Namespace (`namespace.yaml`)
- Creates isolated namespace: `concert-platform`

### 2. ConfigMap & Secrets (`configmap.yaml`)
- **ConfigMap**: Non-sensitive configuration
- **Secret**: Sensitive data (passwords, tokens)

**⚠️ Security Note**: Update secrets before production deployment!

### 3. MySQL (`mysql.yaml`)
- **StatefulSet**: Ensures stable network identity
- **PersistentVolumeClaim**: 10Gi storage for database
- **Service**: ClusterIP for internal access

### 4. Backend (`backend.yaml`)
- **Deployment**: 2-5 replicas with auto-scaling
- **Service**: ClusterIP on port 8080
- **HPA**: Auto-scales based on CPU (70%) and memory (80%)
- Health checks via Spring Boot Actuator

### 5. Frontend (`frontend.yaml`)
- **Deployment**: 2-5 replicas with auto-scaling
- **Service**: LoadBalancer on port 80
- **HPA**: Auto-scales based on CPU (70%) and memory (80%)

### 6. Ingress (`ingress.yaml`)
- Routes external traffic to services
- TLS termination support
- Path-based routing:
  - `/api/*` → Backend
  - `/*` → Frontend

## Resource Requests & Limits

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| MySQL     | 500m        | 1000m     | 512Mi          | 1Gi          |
| Backend   | 500m        | 1000m     | 512Mi          | 1Gi          |
| Frontend  | 100m        | 500m      | 128Mi          | 256Mi        |

## Scaling

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment backend -n concert-platform --replicas=3

# Scale frontend
kubectl scale deployment frontend -n concert-platform --replicas=3
```

### Auto-scaling (HPA)

Both backend and frontend have Horizontal Pod Autoscaler configured:
- Min replicas: 2
- Max replicas: 5
- Triggers: CPU > 70% or Memory > 80%

```bash
# Check HPA status
kubectl get hpa -n concert-platform
```

## Monitoring

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n concert-platform

# Frontend logs
kubectl logs -f deployment/frontend -n concert-platform

# MySQL logs
kubectl logs -f statefulset/mysql -n concert-platform
```

### Exec into Pods

```bash
# Backend shell
kubectl exec -it deployment/backend -n concert-platform -- bash

# MySQL shell
kubectl exec -it statefulset/mysql -n concert-platform -- mysql -u concert_user -p
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n concert-platform

# Check pod logs
kubectl logs <pod-name> -n concert-platform
```

### Database Connection Issues

```bash
# Check MySQL pod status
kubectl get pod -l app=mysql -n concert-platform

# Test connection from backend pod
kubectl exec -it deployment/backend -n concert-platform -- curl mysql-service:3306
```

### Image Pull Errors

```bash
# If using private registry, create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n concert-platform

# Add to deployment spec
# imagePullSecrets:
# - name: regcred
```

## Updating Deployments

### Rolling Update

```bash
# Update backend image
kubectl set image deployment/backend backend=concert-backend:v2.0 -n concert-platform

# Update frontend image
kubectl set image deployment/frontend frontend=concert-frontend:v2.0 -n concert-platform

# Check rollout status
kubectl rollout status deployment/backend -n concert-platform
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n concert-platform

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n concert-platform
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/ingress.yaml
kubectl delete -f k8s/frontend.yaml
kubectl delete -f k8s/backend.yaml
kubectl delete -f k8s/mysql.yaml
kubectl delete -f k8s/configmap.yaml
kubectl delete -f k8s/namespace.yaml

# Or delete namespace (cascades to all resources)
kubectl delete namespace concert-platform
```

## Production Considerations

### Security

1. **Update Secrets**: Change default passwords
2. **RBAC**: Implement Role-Based Access Control
3. **Network Policies**: Restrict pod-to-pod communication
4. **Image Security**: Scan images for vulnerabilities
5. **TLS**: Enable HTTPS with valid certificates

### Persistence

1. **Database Backups**: Implement automated backup strategy
2. **PV Storage Class**: Use production-grade storage (e.g., AWS EBS, GCE PD)
3. **Disaster Recovery**: Plan for data recovery scenarios

### Monitoring & Logging

1. **Prometheus**: Metrics collection
2. **Grafana**: Visualization dashboards
3. **ELK Stack**: Centralized logging
4. **Alerting**: Configure alerts for critical events

### High Availability

1. **Multi-zone Deployment**: Distribute pods across availability zones
2. **Pod Disruption Budgets**: Prevent simultaneous pod termination
3. **Database Replication**: MySQL master-slave or cluster

## Example: Complete Deployment

```bash
#!/bin/bash
# deploy.sh - Complete deployment script

set -e

echo "🚀 Deploying MM Concerts Platform to Kubernetes..."

# 1. Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# 2. Apply configurations
echo "⚙️  Applying configurations..."
kubectl apply -f k8s/configmap.yaml

# 3. Deploy MySQL
echo "🗄️  Deploying MySQL..."
kubectl apply -f k8s/mysql.yaml
kubectl wait --for=condition=ready pod -l app=mysql -n concert-platform --timeout=300s

# 4. Deploy Backend
echo "☕ Deploying Backend..."
kubectl apply -f k8s/backend.yaml
kubectl wait --for=condition=ready pod -l app=backend -n concert-platform --timeout=300s

# 5. Deploy Frontend
echo "🎨 Deploying Frontend..."
kubectl apply -f k8s/frontend.yaml
kubectl wait --for=condition=ready pod -l app=frontend -n concert-platform --timeout=180s

# 6. Configure Ingress
echo "🌐 Configuring Ingress..."
kubectl apply -f k8s/ingress.yaml

# 7. Show status
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Current status:"
kubectl get all -n concert-platform

echo ""
echo "🌐 Access URLs:"
kubectl get ingress concert-ingress -n concert-platform
```

## Support

For issues and questions:
- Check logs: `kubectl logs <pod-name> -n concert-platform`
- Review events: `kubectl get events -n concert-platform`
- Consult main README: `../README.md`
