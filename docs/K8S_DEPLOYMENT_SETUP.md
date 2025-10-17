# Kubernetes Deployment Setup Guide

## Error: Connection Refused to Kubernetes Cluster

### The Problem

```
error validating "k8s/namespace.yaml": Get "https://127.0.0.1:6443/openapi/v2?timeout=32s": 
dial tcp 127.0.0.1:6443: connect: connection refused
```

This means the GitHub Actions workflow cannot connect to your Kubernetes cluster because:
1. **Missing `KUBE_CONFIG` secret** - The kubeconfig is not configured in GitHub
2. **No K8s cluster available** - You need an actual cluster to deploy to
3. **Invalid kubeconfig** - The config might be expired or pointing to localhost

---

## Solution Options

### Option 1: Disable K8s Deployment (Quick Fix)

If you don't have a Kubernetes cluster yet or want to skip deployment:

1. **Add a repository variable:**
   - Go to GitHub repo: Settings → Secrets and variables → Actions → Variables tab
   - Click "New repository variable"
   - Name: `K8S_ENABLED`
   - Value: `false`

2. **Result:** The workflow will:
   - ✅ Run backend tests
   - ✅ Run frontend tests  
   - ✅ Build and push Docker images
   - ⏭️ Skip Kubernetes deployment
   - ✅ Send notifications

---

### Option 2: Set Up Kubernetes Deployment (Full Setup)

#### Prerequisites

You need ONE of these Kubernetes options:

**Cloud Providers:**
- ☁️ **Azure AKS** (Azure Kubernetes Service)
- ☁️ **AWS EKS** (Elastic Kubernetes Service)
- ☁️ **Google GKE** (Google Kubernetes Engine)
- ☁️ **DigitalOcean Kubernetes**

**Local/Self-Hosted:**
- 🏠 **Minikube** (local development)
- 🏠 **k3s** (lightweight K8s)
- 🏠 **Docker Desktop** (includes K8s)
- 🏠 **Self-hosted cluster** (with public IP accessible from GitHub)

#### Step 1: Get Your Kubeconfig

**For Cloud Providers:**

```bash
# Azure AKS
az aks get-credentials --resource-group <rg-name> --name <cluster-name>

# AWS EKS
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Google GKE
gcloud container clusters get-credentials <cluster-name> --region <region>

# DigitalOcean
doctl kubernetes cluster kubeconfig save <cluster-name>
```

**For Local Clusters:**

```bash
# Usually already at ~/.kube/config
cat ~/.kube/config
```

#### Step 2: Create GitHub Service Account (Recommended)

Instead of using your personal kubeconfig, create a service account:

```bash
# Create service account
kubectl create serviceaccount github-deployer -n concert-platform

# Create cluster role binding
kubectl create clusterrolebinding github-deployer-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=concert-platform:github-deployer

# Get the service account token (K8s 1.24+)
kubectl create token github-deployer -n concert-platform --duration=87600h

# Create kubeconfig for service account
# (See detailed script below)
```

**Kubeconfig Creation Script:**

```bash
#!/bin/bash
# save as: create-github-kubeconfig.sh

CLUSTER_NAME=$(kubectl config current-context)
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(kubectl create token github-deployer -n concert-platform --duration=87600h)

cat > github-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${API_SERVER}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: github-deployer
  name: github-context
current-context: github-context
users:
- name: github-deployer
  user:
    token: ${TOKEN}
EOF

echo "✅ Kubeconfig created: github-kubeconfig.yaml"
```

Run it:
```bash
chmod +x create-github-kubeconfig.sh
./create-github-kubeconfig.sh
```

#### Step 3: Add Secrets to GitHub

1. **Encode the kubeconfig:**

```bash
# Base64 encode the kubeconfig
cat github-kubeconfig.yaml | base64 | pbcopy  # macOS
# or
cat github-kubeconfig.yaml | base64 -w 0      # Linux (copy the output)
```

2. **Add to GitHub:**
   - Go to: https://github.com/MorningMores/develop/settings/secrets/actions
   - Click "New repository secret"
   - Name: `KUBE_CONFIG`
   - Value: Paste the base64-encoded string
   - Click "Add secret"

3. **Enable K8s deployment:**
   - Go to: https://github.com/MorningMores/develop/settings/variables/actions
   - Click "New repository variable"
   - Name: `K8S_ENABLED`
   - Value: `true`
   - Click "Add variable"

#### Step 4: Verify Setup

Trigger the workflow manually:
1. Go to Actions → K8s Deployment Pipeline
2. Click "Run workflow"
3. Watch the logs for the "🔍 Verify Kubernetes connection" step

Expected output:
```
✅ Successfully connected to Kubernetes cluster
Kubernetes control plane is running at https://xxx
```

---

## Troubleshooting

### Error: "KUBE_CONFIG secret is not set"

**Fix:**
- Follow Step 3 above to add the `KUBE_CONFIG` secret

### Error: "Cannot connect to Kubernetes cluster"

**Possible causes:**
1. **Cluster is not publicly accessible** - GitHub Actions runners need internet access to your cluster
2. **Firewall blocking** - Allow GitHub Actions IP ranges
3. **Token expired** - Create a new service account token
4. **Wrong context** - Verify the kubeconfig points to the right cluster

**Solution for cloud providers:**
- Ensure cluster API server is publicly accessible
- Add GitHub Actions IP ranges to firewall allowlist

**GitHub Actions IP Ranges:**
- Check: https://api.github.com/meta (look for "actions" IPs)

### Error: "Insufficient permissions"

**Fix:**
```bash
# Grant more permissions to service account
kubectl create clusterrolebinding github-deployer-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=concert-platform:github-deployer
```

### Workflow Skips Deployment

Check if `K8S_ENABLED` variable is set to `true`:
- Go to Settings → Secrets and variables → Actions → Variables
- Ensure `K8S_ENABLED = true`

---

## Security Best Practices

### ✅ DO:
- Use a dedicated service account for GitHub Actions
- Set token expiration (don't use permanent tokens)
- Limit permissions with RBAC (use specific roles instead of cluster-admin)
- Rotate credentials regularly
- Use GitHub Environments for additional protection

### ❌ DON'T:
- Don't commit kubeconfig files to git
- Don't use your personal kubeconfig
- Don't grant unnecessary permissions
- Don't expose cluster publicly without firewall rules

---

## Alternative: Use GitHub Environments

For better security, use GitHub Environments:

1. **Create environment:**
   - Settings → Environments → New environment
   - Name: `kubernetes-production`
   - Add protection rules (require reviewers, etc.)

2. **Add secret to environment:**
   - Add `KUBE_CONFIG` to the environment (not repository)

3. **Update workflow:**
```yaml
deploy-k8s:
  name: Deploy to Kubernetes
  runs-on: ubuntu-latest
  needs: build-images
  environment: kubernetes-production  # Add this line
  timeout-minutes: 20
```

---

## Quick Reference

### Required Secrets
| Secret | Description | How to get |
|--------|-------------|------------|
| `KUBE_CONFIG` | Base64-encoded kubeconfig | `cat kubeconfig.yaml \| base64` |

### Required Variables  
| Variable | Value | Description |
|----------|-------|-------------|
| `K8S_ENABLED` | `true` or `false` | Enable/disable K8s deployment |

### Optional Secrets
| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK_URL` | Slack notifications |
| `SLACK_BOT_TOKEN` | Alternative to webhook |

---

## Testing Locally

Before setting up GitHub Actions, test locally:

```bash
# Test cluster connection
kubectl cluster-info

# Test applying manifests
kubectl apply -f k8s/namespace.yaml --dry-run=client

# Apply all manifests
kubectl apply -f k8s/

# Check deployment
kubectl get all -n concert-platform
```

---

**Last Updated:** October 18, 2025  
**Status:** ⚠️ K8s deployment requires setup  
**Next Steps:** Choose Option 1 (disable) or Option 2 (full setup)
