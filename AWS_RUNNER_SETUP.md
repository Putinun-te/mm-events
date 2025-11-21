# AWS EKS Self-Hosted GitHub Actions Runner Setup

## ✅ What's Configured

All GitHub Actions workflows now use AWS EKS self-hosted runners with labels:
- `self-hosted`
- `eks`
- `singapore`

### Updated Workflows:
1. **full-pipeline.yml** - Complete CI/CD pipeline
2. **quick-tests.yml** - Fast unit tests
3. **eks-runner.yml** - EKS-specific tests

## 🚀 Setup Instructions

### 1. Verify EKS Cluster is Running

```bash
# Check EKS cluster status
aws eks describe-cluster --name concert-eks-cluster --region ap-southeast-1

# Get cluster endpoint
kubectl cluster-info
```

### 2. Deploy GitHub Actions Runner to EKS

The runner deployment is already configured in `k8s/github-runner.yaml`. Deploy it:

```bash
# Create namespace (if not exists)
kubectl create namespace actions-runner-system

# Create GitHub token secret
kubectl create secret generic github-token \
  --from-literal=GITHUB_TOKEN=<your-github-pat> \
  -n actions-runner-system

# Deploy the runner
kubectl apply -f k8s/github-runner.yaml

# Check runner status
kubectl get pods -n actions-runner-system
kubectl logs -f <runner-pod-name> -n actions-runner-system
```

### 3. Create GitHub Personal Access Token (PAT)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
   - `admin:org` → `manage_runners:org` (if using org-level runners)
4. Copy the token

### 4. Verify Runner Registration

Check if runners are registered:

```bash
# In GitHub repo
Settings → Actions → Runners

# You should see runners with labels:
# - self-hosted
# - eks
# - singapore
```

### 5. Test the Setup

Push a commit to trigger the workflow:

```bash
git commit --allow-empty -m "Test AWS runner"
git push devops release/v1.0.0
```

Check Actions tab to see if jobs run on your EKS runners.

## 📋 Runner Configuration

### Current Setup:
- **Location**: EKS cluster in `ap-southeast-1` (Singapore)
- **Labels**: `self-hosted`, `eks`, `singapore`
- **Namespace**: `actions-runner-system`
- **Replicas**: Configurable in deployment

### Benefits:
- ✅ Faster builds (no cold start)
- ✅ Cost savings (use existing EKS infrastructure)
- ✅ Better control over build environment
- ✅ Access to private AWS resources
- ✅ Consistent build environment

## 🔧 Troubleshooting

### Runner Not Appearing

```bash
# Check pod status
kubectl get pods -n actions-runner-system

# Check logs
kubectl logs -l app=github-runner -n actions-runner-system

# Verify secret
kubectl get secret github-token -n actions-runner-system
```

### Jobs Stuck in Queue

```bash
# Scale up runners
kubectl scale deployment github-runner -n actions-runner-system --replicas=3

# Check runner capacity
kubectl top pods -n actions-runner-system
```

### Authentication Issues

```bash
# Recreate token secret
kubectl delete secret github-token -n actions-runner-system
kubectl create secret generic github-token \
  --from-literal=GITHUB_TOKEN=<new-token> \
  -n actions-runner-system

# Restart runners
kubectl rollout restart deployment github-runner -n actions-runner-system
```

## 🔄 Fallback to GitHub Hosted Runners

If you need to temporarily use GitHub-hosted runners, change in workflows:

```yaml
# From:
runs-on: [self-hosted, eks, singapore]

# To:
runs-on: ubuntu-latest
```

## 📊 Monitoring

```bash
# Watch runner pods
kubectl get pods -n actions-runner-system -w

# Check resource usage
kubectl top pods -n actions-runner-system

# View runner logs
kubectl logs -f deployment/github-runner -n actions-runner-system
```

## 🔐 Security Notes

- Store GitHub PAT in Kubernetes secrets
- Use least privilege IAM roles for runners
- Regularly rotate GitHub tokens
- Monitor runner activity in GitHub Actions logs
- Restrict runner access to specific repositories if needed

## 📚 Additional Resources

- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Actions Runner Controller](https://github.com/actions/actions-runner-controller)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
