# K8s Deployment Setup Required

## ⚠️ Current Status

The K8s deployment step **always runs** and requires proper configuration to succeed.

## ✅ Required: Add KUBE_CONFIG Secret

To fix the connection error, you need to add your Kubernetes configuration:

### Quick Setup:

1. **Get your kubeconfig:**
   ```bash
   cat ~/.kube/config | base64
   ```

2. **Add to GitHub:**
   - Go to: https://github.com/MorningMores/develop/settings/secrets/actions
   - Click **"New repository secret"**
   - Set:
     - **Name:** `KUBE_CONFIG`
     - **Value:** Paste the base64 string from step 1
   - Click **"Add secret"**

3. **Re-run the workflow**

### Result

The next workflow run will:
- ✅ Run backend tests
- ✅ Run frontend tests
- ✅ Build Docker images
- ✅ Push to GitHub Container Registry
- ✅ **Deploy to Kubernetes cluster**
- ✅ Send notifications

---

## 🚀 Want to Enable K8s Deployment Later?

See the full guide: [`docs/K8S_DEPLOYMENT_SETUP.md`](./K8S_DEPLOYMENT_SETUP.md)

You'll need:
1. A Kubernetes cluster (AKS, EKS, GKE, or local)
2. Kubeconfig access
3. Add `KUBE_CONFIG` secret to GitHub
4. Set `K8S_ENABLED=true`

---

## What Changed

### Workflow Improvements (`.github/workflows/k8s-deploy.yml`)

1. **Made K8s deployment conditional:**
   ```yaml
   if: (github.event_name == 'push' || github.event_name == 'workflow_dispatch') 
       && vars.K8S_ENABLED == 'true'
   ```

2. **Added secret validation:**
   - Checks if `KUBE_CONFIG` exists
   - Shows helpful error message if missing

3. **Added connection verification:**
   - Tests cluster connection before deployment
   - Shows current context and available contexts
   - Fails fast with clear error messages

### Benefits

- ✅ Workflow won't fail if K8s not configured
- ✅ Clear error messages when something is wrong
- ✅ Easy to enable/disable deployment
- ✅ Better debugging information

---

## Current Workflow Status

**Without KUBE_CONFIG secret:** ❌ Deployment fails with clear error message

**With KUBE_CONFIG secret:** ✅ Full deployment to K8s cluster

---

## Important Notes

### Prerequisites

You MUST have one of these:
- ☁️ **Cloud Kubernetes cluster** (AKS, EKS, GKE, DigitalOcean)
  - Must be publicly accessible from internet
  - GitHub Actions runners need to reach the API server
  
- 🏠 **Local cluster with public access** (k3s, Docker Desktop)
  - Requires public IP or tunnel (ngrok, cloudflared)
  - Not recommended for production

### Common Issues

**❌ "dial tcp 127.0.0.1:6443: connection refused"**
- Your kubeconfig points to localhost
- Solution: Use a cloud cluster or expose local cluster publicly

**❌ "Cannot connect to Kubernetes cluster"**
- Cluster is not accessible from GitHub Actions
- Check firewall rules
- Verify cluster is running

---

**Next Step:** Add the `KUBE_CONFIG` secret following the instructions above!
