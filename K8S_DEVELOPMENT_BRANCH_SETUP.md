# K8s Development Branch - Setup Guide

## 🎯 Overview

The `k8s-development` branch is a production-ready Kubernetes deployment configuration for the Concert Platform. It includes:

✅ **K8s Manifests** - Complete deployment specifications  
✅ **CI/CD Pipeline** - Automated build, test, and deploy  
✅ **Docker Multi-stage Builds** - Optimized container images  
✅ **Deployment Helper** - CLI tool for easy management  
✅ **Comprehensive Docs** - Full deployment guide  

## 📋 Prerequisites

### Local Machine
- `kubectl` - Kubernetes command-line tool
- `docker` - For building images locally (optional)
- `git` - Version control
- Bash shell

### Kubernetes Cluster
- Kubernetes 1.24+ (1.28+ recommended)
- kubectl access configured
- Internet access for image pulls
- Storage provisioner (for MySQL PVC)

### GitHub Setup
- GitHub repository with Actions enabled
- Docker registry (ghcr.io by default)

## 🚀 Quick Start

### 1. Clone and Switch Branch
```bash
git clone https://github.com/MorningMores/Test.git
cd Test
git checkout k8s-development
```

### 2. Set GitHub Secrets
In your GitHub repo settings, add:
```
Name: KUBE_CONFIG
Value: <base64-encoded kubeconfig>
```

To encode kubeconfig:
```bash
# macOS
cat ~/.kube/config | base64 | pbcopy

# Linux
cat ~/.kube/config | base64 | xclip
```

### 3. Verify Cluster Access
```bash
kubectl cluster-info
kubectl get nodes
```

### 4. Deploy via Helper Script
```bash
# Make it executable
chmod +x k8s-deploy-helper.sh

# Deploy everything
./k8s-deploy-helper.sh deploy

# Enter MySQL password when prompted
```

### 5. Check Status
```bash
./k8s-deploy-helper.sh status

# Or manually
kubectl get all -n concert-platform
```

## 📁 Project Structure

```
k8s-development/
├── .github/workflows/
│   └── k8s-deploy.yml              # CI/CD pipeline for K8s
├── k8s/
│   ├── namespace.yaml              # Namespace definition
│   ├── configmap.yaml              # Environment configuration
│   ├── mysql.yaml                  # MySQL StatefulSet
│   ├── backend.yaml                # Backend Deployment
│   ├── frontend.yaml               # Frontend Deployment
│   └── ingress.yaml                # Ingress controller
├── main_backend/
│   ├── Dockerfile.k8s              # Multi-stage backend build
│   └── ... (rest of backend files)
├── main_frontend/concert1/
│   ├── Dockerfile.k8s              # Multi-stage frontend build
│   └── ... (rest of frontend files)
├── k8s-deploy-helper.sh            # Deployment helper CLI
└── K8S_DEPLOYMENT_GUIDE_*.md       # Full deployment guide
```

## 🔄 CI/CD Pipeline

Triggered on push to `k8s-development` branch:

```
Checkout Code
    ↓
Backend Tests & Build (Maven)
Frontend Tests & Build (Vitest)
    ↓
Build Docker Images (ghcr.io)
    ↓
Deploy to Kubernetes
    ↓
Verify & Report
```

### Pipeline Stages

1. **Unit Tests**
   - Backend: Maven tests with JUnit 5
   - Frontend: Vitest with Vue 3

2. **Build**
   - Backend: Maven package → JAR
   - Frontend: Nuxt build → .output/

3. **Docker Images**
   - Multi-stage builds for size optimization
   - Pushed to ghcr.io
   - Tagged with commit SHA

4. **K8s Deployment**
   - Create namespace
   - Deploy MySQL
   - Deploy backend & frontend
   - Configure ingress

## 🛠️ Deployment Helper Usage

```bash
# Full deployment
./k8s-deploy-helper.sh deploy

# Check status
./k8s-deploy-helper.sh status

# View logs
./k8s-deploy-helper.sh logs backend
./k8s-deploy-helper.sh logs frontend
./k8s-deploy-helper.sh logs mysql

# Scale deployment
./k8s-deploy-helper.sh scale backend 5

# Restart deployment
./k8s-deploy-helper.sh restart backend

# Rollback to previous version
./k8s-deploy-helper.sh rollback backend

# Cleanup everything
./k8s-deploy-helper.sh cleanup

# Show help
./k8s-deploy-helper.sh help
```

## 📊 Architecture

```
┌─────────────────────────────────────────────┐
│     GitHub Actions CI/CD Pipeline           │
│  (runs on: push to k8s-development)         │
└────────────────┬────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      ↓                     ↓
   Tests                  Build
   Maven                  Docker
   Vitest                (ghcr.io)
      │                     │
      └──────────┬──────────┘
                 ↓
    ┌────────────────────────┐
    │ Kubernetes Cluster     │
    ├────────────────────────┤
    │ ┌──────────────────┐   │
    │ │ Ingress (ext)    │   │
    │ └────────┬─────────┘   │
    │          │             │
    │  ┌───────┴────────┐    │
    │  ↓                ↓    │
    │ Frontend       Backend │
    │ (2x Pods)      (2x Pods)│
    │  │                │    │
    │  └────────┬──────┘     │
    │           ↓            │
    │        MySQL           │
    │    (StatefulSet)       │
    │                        │
    └────────────────────────┘
```

## 🔐 Security Best Practices

1. **Use RBAC** - Configure role-based access control
2. **Network Policies** - Restrict pod-to-pod communication
3. **Secrets Management** - Use sealed-secrets or Vault
4. **Resource Limits** - Set CPU/memory constraints
5. **Health Checks** - Liveness and readiness probes configured
6. **Non-root Users** - Containers run as non-root

## 📝 Configuration

### Environment Variables
Edit `k8s/configmap.yaml`:
```yaml
SPRING_DATASOURCE_URL: jdbc:mysql://mysql-service:3306/concert_db
SPRING_DATASOURCE_USERNAME: concert_user
SPRING_PROFILES_ACTIVE: k8s
```

### Database Password
Create secret manually:
```bash
kubectl create secret generic concert-secrets \
  -n concert-platform \
  --from-literal=SPRING_DATASOURCE_PASSWORD=your-secure-password
```

### Domain/Ingress
Edit `k8s/ingress.yaml`:
```yaml
hosts:
- host: your-domain.com
  paths:
  - path: /
    pathType: Prefix
    backend:
      service:
        name: frontend-service
```

## 📈 Scaling

### Horizontal Scaling
```bash
# Scale backend to 5 replicas
./k8s-deploy-helper.sh scale backend 5

# Scale frontend to 3 replicas
./k8s-deploy-helper.sh scale frontend 3
```

### Auto-scaling (HPA)
Apply HPA manifest:
```bash
kubectl apply -f k8s/hpa.yaml
```

## 🔄 Rolling Updates

Automatic with zero downtime:
- RollingUpdate strategy configured
- maxSurge: 1 (one extra pod)
- maxUnavailable: 0 (no downtime)
- Health checks verify readiness

```bash
# Trigger update by pushing to k8s-development
git push origin k8s-development

# Monitor rollout
kubectl rollout status deployment/backend -n concert-platform

# View history
kubectl rollout history deployment/backend -n concert-platform
```

## 🚨 Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n concert-platform
kubectl logs <pod-name> -n concert-platform
```

### Database connection failed
```bash
# Test connectivity from pod
kubectl exec -it <backend-pod> -n concert-platform -- \
  curl -v http://mysql-service:3306

# Or use MySQL client
kubectl run -it --rm mysql-test --image=mysql:8.0 --restart=Never -n concert-platform -- \
  mysql -h mysql-service -u concert_user -p -e "SELECT VERSION();"
```

### Image pull errors
```bash
# Check image pull secrets
kubectl get secrets -n concert-platform

# Describe pod for events
kubectl describe pod <pod-name> -n concert-platform
```

## 📚 Full Documentation

See `K8S_DEPLOYMENT_GUIDE_K8S_DEV_BRANCH.md` for:
- Detailed deployment walkthrough
- Manual step-by-step deployment
- All kubectl commands explained
- Monitoring and debugging
- Rollback procedures
- Scaling strategies

## 🔄 Merging to Main

When deployment is verified and stable:

```bash
# Switch to main
git checkout main
git pull

# Merge k8s-development
git merge k8s-development

# Push to main
git push
```

## 📞 Support

For issues or questions:
1. Check logs: `./k8s-deploy-helper.sh logs [component]`
2. View status: `./k8s-deploy-helper.sh status`
3. Review guide: `K8S_DEPLOYMENT_GUIDE_K8S_DEV_BRANCH.md`

## ✅ Checklist

Before deploying to production:

- [ ] KUBE_CONFIG secret added to GitHub
- [ ] Kubeconfig file is valid and accessible
- [ ] Cluster has minimum 3 nodes
- [ ] Storage provisioner configured
- [ ] Database backup strategy in place
- [ ] Monitoring/logging setup (optional)
- [ ] Domain/ingress configured
- [ ] SSL/TLS certificates ready
- [ ] Resource quotas defined
- [ ] All tests passing in CI/CD

---

**Happy Deploying! 🚀**
