# Deploy Backend to EKS - Windows Instructions

## Step 1: Wav Grants Access (Run Once)

**Wav needs to run this in PowerShell or Command Prompt:**

```cmd
cd k8s
grant-eks-access.bat
```

**Or manually:**

```powershell
# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name concert-cluster

# Edit aws-auth
kubectl edit configmap aws-auth -n kube-system

# Add this under mapUsers:
#   - userarn: arn:aws:iam::123456789012:root
#     username: root-admin
#     groups:
#       - system:masters
```

---

## Step 2: Deploy Backend (After Access Granted)

### Build and Push Docker Image

```cmd
cd main_backend

REM Login to ECR
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com

REM Build image
docker build -t concert-backend .

REM Tag image
docker tag concert-backend:latest 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/concert-backend:latest

REM Push to ECR
docker push 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/concert-backend:latest
```

### Deploy to Kubernetes

```cmd
cd ..

REM Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name concert-cluster

REM Deploy backend
kubectl apply -f k8s\backend-deployment.yaml

REM Check status
kubectl get pods
kubectl get svc concert-backend
```

### Get Load Balancer URL

```cmd
kubectl get svc concert-backend -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
```

---

## Step 3: Update Frontend

Update `main_frontend/concert1/nuxt.config.ts`:

```typescript
backendBaseUrl: 'http://YOUR-LOAD-BALANCER-URL'
```

Then rebuild and deploy frontend:

```cmd
cd main_frontend\concert1
npm run generate
aws s3 sync .output\public\ s3://concert-web-singapore-123456789012/ --delete
```

---

## Troubleshooting

**Check pods:**
```cmd
kubectl get pods
kubectl logs -f deployment/concert-backend
```

**Check service:**
```cmd
kubectl describe svc concert-backend
```

**Restart deployment:**
```cmd
kubectl rollout restart deployment/concert-backend
```
