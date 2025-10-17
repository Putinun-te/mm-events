# Docker Desktop K8s - Not Compatible with GitHub Actions

## ⚠️ The Problem

Your kubeconfig is using **Docker Desktop's Kubernetes**, which:
- Runs on `127.0.0.1:6443` (localhost)
- Is **not accessible** from GitHub Actions runners
- Only works on your local machine

### Current Configuration:
```
Cluster: docker-desktop
Server: https://127.0.0.1:6443
```

GitHub Actions runners are in the cloud and **cannot connect to your local machine**.

---

## ✅ Solutions

### Option 1: Disable K8s Deployment (Current - RECOMMENDED)

The workflow is now configured to skip Kubernetes deployment:

```yaml
if: false  # Temporarily disabled
```

**Benefits:**
- ✅ Workflow completes successfully
- ✅ Images still built and pushed to GHCR
- ✅ Can deploy manually from your local machine
- ✅ No cloud costs

**Manual Deployment from Local:**
```bash
# Your images are in GHCR, update K8s to use them:
kubectl set image deployment/backend \
  backend=ghcr.io/morningmores/develop/concert-backend:latest \
  -n concert-platform

kubectl set image deployment/frontend \
  frontend=ghcr.io/morningmores/develop/concert-frontend:latest \
  -n concert-platform
```

---

### Option 2: Use a Cloud Kubernetes Cluster

To enable full CI/CD deployment, you need a **publicly accessible** K8s cluster:

#### 2A. Azure AKS (Recommended)

**Free Tier Available:**
```bash
# Create resource group
az group create --name concert-rg --location eastus

# Create AKS cluster (free control plane, pay for nodes)
az aks create \
  --resource-group concert-rg \
  --name concert-cluster \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group concert-rg --name concert-cluster

# Get kubeconfig for GitHub
cat ~/.kube/config | base64
```

**Monthly Cost:** ~$30-50 for 1 small node

#### 2B. DigitalOcean Kubernetes

**Cheapest Option:**
```bash
# Create cluster via DO web console or CLI
doctl kubernetes cluster create concert-cluster \
  --size s-1vcpu-2gb \
  --count 1

# Get credentials
doctl kubernetes cluster kubeconfig save concert-cluster

# Encode for GitHub
cat ~/.kube/config | base64
```

**Monthly Cost:** ~$12 for 1 small node

#### 2C. Google GKE

**Free Tier Available:**
```bash
# Create cluster
gcloud container clusters create concert-cluster \
  --zone us-central1-a \
  --num-nodes 1 \
  --machine-type e2-micro

# Get credentials
gcloud container clusters get-credentials concert-cluster --zone us-central1-a

# Encode for GitHub
cat ~/.kube/config | base64
```

**Monthly Cost:** Free tier available, then ~$25/month

#### 2D. AWS EKS

```bash
# Create cluster (via eksctl)
eksctl create cluster \
  --name concert-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.small \
  --nodes 1

# Get credentials
aws eks update-kubeconfig --region us-east-1 --name concert-cluster

# Encode for GitHub
cat ~/.kube/config | base64
```

**Monthly Cost:** ~$75 (control plane: $73, plus node costs)

---

### Option 3: Expose Docker Desktop via Tunnel (NOT RECOMMENDED)

This is **insecure** and **unreliable** but possible for testing:

```bash
# Install cloudflared or ngrok
brew install cloudflared

# Create tunnel to localhost:6443
cloudflared tunnel --url tcp://127.0.0.1:6443

# This gives you a public URL like: tcp://xxx.trycloudflare.com:port
```

**Issues:**
- 🔴 Security risk (exposing your local cluster)
- 🔴 Unreliable (depends on your machine being on)
- 🔴 Not suitable for production
- 🔴 Tunnel may disconnect

---

## 🎯 Recommended Approach

### For Development/Learning:
1. **Keep deployment disabled** in GitHub Actions
2. Use **Docker Compose** for local development
3. Deploy manually to Docker Desktop K8s from your machine
4. Images automatically built and available in GHCR

### For Production:
1. **Use a cloud provider** (DigitalOcean for budget, Azure/AWS for enterprise)
2. Add `KUBE_CONFIG` secret with cloud cluster config
3. Enable deployment in workflow
4. Full CI/CD automation

---

## 📝 Current Workflow Behavior

With `if: false` in the deploy-k8s job:

```
✅ Backend Tests      → Pass
✅ Frontend Tests     → Pass  
✅ Build Images       → Pass
✅ Push to GHCR       → Pass (images available)
⏭️ Deploy K8s         → Skipped
✅ Notifications      → Pass

Result: ✅ Workflow succeeds
```

---

## 🔄 Manual Deploy Workflow

After GitHub Actions builds and pushes images:

```bash
# 1. Pull latest images
docker pull ghcr.io/morningmores/develop/concert-backend:latest
docker pull ghcr.io/morningmores/develop/concert-frontend:latest

# 2. Apply to your local K8s
kubectl apply -f k8s/

# 3. Update deployments to use new images
kubectl rollout restart deployment/backend -n concert-platform
kubectl rollout restart deployment/frontend -n concert-platform

# 4. Check status
kubectl get pods -n concert-platform
```

---

## 💰 Cost Comparison

| Provider | Monthly Cost | Free Tier | Best For |
|----------|-------------|-----------|----------|
| **Docker Desktop** | $0 | Yes | Local dev only |
| **DigitalOcean** | $12 | No | Budget projects |
| **Azure AKS** | $30-50 | Some | Enterprise |
| **GKE** | $25+ | Yes (limited) | Google ecosystem |
| **AWS EKS** | $75+ | No | AWS ecosystem |

---

## ✅ Next Steps

**For now (Development):**
1. ✅ Leave deployment disabled (`if: false`)
2. ✅ Workflow will pass and build images
3. ✅ Deploy manually to Docker Desktop
4. ✅ No additional costs

**When ready for production:**
1. Choose a cloud provider
2. Create K8s cluster
3. Add `KUBE_CONFIG` secret
4. Change `if: false` to `if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'`
5. Full automation enabled

---

**Current Status:** ✅ Workflow fixed - K8s deployment disabled  
**Commit and push to apply the fix!**
