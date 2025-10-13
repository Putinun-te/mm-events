# Kubernetes Deployment Guide

## 📋 Overview

This directory contains Kubernetes manifests for deploying the Concert Event Management System to a Kubernetes cluster.

## 🗂️ Manifest Files

| File | Description |
|------|-------------|
| `01-namespace.yaml` | Creates `concert-app` namespace |
| `02-mysql-secret.yaml` | MySQL credentials (root password, user, database) |
| `03-backend-secret.yaml` | Backend secrets (datasource password, JWT secret) |
| `04-mysql-configmap.yaml` | MySQL initialization script |
| `05-backend-configmap.yaml` | Backend application.properties |
| `06-mysql-pvc.yaml` | Persistent volume claim for MySQL data (10Gi) |
| `07-mysql-deployment.yaml` | MySQL 8.0 deployment with health checks |
| `08-mysql-service.yaml` | MySQL headless service (ClusterIP: None) |
| `09-backend-deployment.yaml` | Backend Spring Boot app (2 replicas) |
| `10-backend-service.yaml` | Backend LoadBalancer service (port 8080) |
| `11-ingress.yaml` | Nginx Ingress for external access (optional) |
| `12-backend-hpa.yaml` | Horizontal Pod Autoscaler (2-10 replicas) |

## 🚀 Deployment Instructions

### Prerequisites

1. **Kubernetes Cluster** (one of):
   - Local: Minikube, Kind, Docker Desktop
   - Cloud: GKE, EKS, AKS
   - On-premise: kubeadm cluster

2. **kubectl** installed and configured:
   ```bash
   kubectl version --client
   kubectl cluster-info
   ```

3. **Ingress Controller** (optional, for 11-ingress.yaml):
   ```bash
   # For Nginx Ingress Controller
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
   ```

4. **Docker Image** built and pushed to registry:
   ```bash
   # Build backend Docker image
   cd main_backend
   docker build -t your-registry/concert-backend:latest .
   docker push your-registry/concert-backend:latest
   ```

### Step 1: Create Namespace

```bash
kubectl apply -f k8s/01-namespace.yaml
```

**Verify**:
```bash
kubectl get namespace concert-app
```

### Step 2: Create Secrets

⚠️ **IMPORTANT**: Update secrets with production values before deploying!

```bash
# Option 1: Apply directly (NOT RECOMMENDED for production)
kubectl apply -f k8s/02-mysql-secret.yaml
kubectl apply -f k8s/03-backend-secret.yaml

# Option 2: Create secrets from command line (RECOMMENDED)
kubectl create secret generic mysql-secret \
  --from-literal=MYSQL_ROOT_PASSWORD='YOUR_STRONG_ROOT_PASSWORD' \
  --from-literal=MYSQL_DATABASE='concert_db' \
  --from-literal=MYSQL_USER='concert_user' \
  --from-literal=MYSQL_PASSWORD='YOUR_STRONG_USER_PASSWORD' \
  --namespace=concert-app

kubectl create secret generic backend-secret \
  --from-literal=SPRING_DATASOURCE_PASSWORD='YOUR_STRONG_USER_PASSWORD' \
  --from-literal=JWT_SECRET='YOUR_256_BIT_JWT_SECRET_KEY' \
  --namespace=concert-app
```

**Verify**:
```bash
kubectl get secrets -n concert-app
```

### Step 3: Create ConfigMaps

```bash
kubectl apply -f k8s/04-mysql-configmap.yaml
kubectl apply -f k8s/05-backend-configmap.yaml
```

**Verify**:
```bash
kubectl get configmaps -n concert-app
kubectl describe configmap backend-config -n concert-app
```

### Step 4: Create Persistent Storage

```bash
kubectl apply -f k8s/06-mysql-pvc.yaml
```

**Verify**:
```bash
kubectl get pvc -n concert-app
# Wait for STATUS to be "Bound"
```

### Step 5: Deploy MySQL

```bash
kubectl apply -f k8s/07-mysql-deployment.yaml
kubectl apply -f k8s/08-mysql-service.yaml
```

**Verify**:
```bash
# Check deployment
kubectl get deployment mysql -n concert-app

# Check pods
kubectl get pods -n concert-app -l app=mysql

# Wait for pod to be ready (may take 30-60 seconds)
kubectl wait --for=condition=ready pod -l app=mysql -n concert-app --timeout=120s

# Check logs
kubectl logs -f deployment/mysql -n concert-app

# Check service
kubectl get service mysql -n concert-app
```

**Test MySQL Connection** (from another pod):
```bash
# Create test pod
kubectl run mysql-test --rm -it --restart=Never \
  --image=mysql:8.0 \
  --namespace=concert-app \
  --env="MYSQL_PWD=concert_password" \
  -- mysql -h mysql -u concert_user concert_db -e "SHOW TABLES;"
```

### Step 6: Deploy Backend

**Update Image Reference** in `09-backend-deployment.yaml`:
```yaml
# Line 52: Replace with your actual registry/image
image: your-registry/concert-backend:latest
```

```bash
# Apply deployment
kubectl apply -f k8s/09-backend-deployment.yaml
kubectl apply -f k8s/10-backend-service.yaml
```

**Verify**:
```bash
# Check deployment
kubectl get deployment backend -n concert-app

# Check pods (should have 2 replicas)
kubectl get pods -n concert-app -l app=backend

# Wait for pods to be ready (may take 60-90 seconds)
kubectl wait --for=condition=ready pod -l app=backend -n concert-app --timeout=180s

# Check logs
kubectl logs -f deployment/backend -n concert-app

# Check service
kubectl get service backend -n concert-app
```

**Test Backend Health**:
```bash
# Get LoadBalancer external IP (may take a few minutes)
kubectl get service backend -n concert-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Or port-forward to test locally
kubectl port-forward service/backend 8080:8080 -n concert-app

# In another terminal, test endpoints
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/auth/test
```

### Step 7: Deploy Ingress (Optional)

**Prerequisites**:
- Nginx Ingress Controller installed
- DNS record pointing to your cluster

**Update Domain** in `11-ingress.yaml`:
```yaml
# Line 25 & 26: Replace with your actual domain
- host: concert.example.com
  secretName: concert-tls
```

```bash
kubectl apply -f k8s/11-ingress.yaml
```

**Verify**:
```bash
kubectl get ingress -n concert-app
kubectl describe ingress concert-ingress -n concert-app
```

### Step 8: Enable Autoscaling (Optional)

**Prerequisites**:
- Metrics Server installed in cluster

```bash
# Install Metrics Server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Apply HPA
kubectl apply -f k8s/12-backend-hpa.yaml
```

**Verify**:
```bash
kubectl get hpa -n concert-app
kubectl describe hpa backend-hpa -n concert-app
```

## 🧪 Testing Deployment

### 1. Check All Resources

```bash
kubectl get all -n concert-app
```

Expected output:
```
NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
pod/backend-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
pod/mysql-xxxxxxxxxx-xxxxx     1/1     Running   0          10m

NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
service/backend   LoadBalancer   10.96.123.45    34.123.45.67   8080:30080/TCP   5m
service/mysql     ClusterIP      None            <none>          3306/TCP         10m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend   2/2     2            2           5m
deployment.apps/mysql     1/1     1            1           10m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/backend-xxxxxxxxxx   2         2         2       5m
replicaset.apps/mysql-xxxxxxxxxx     1         1         1       10m

NAME                                          REFERENCE            TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/backend   Deployment/backend   45%/70%, 60%/80%              2         10        2          2m
```

### 2. Test API Endpoints

```bash
# Get backend URL
BACKEND_URL=$(kubectl get service backend -n concert-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Health check
curl http://$BACKEND_URL:8080/actuator/health

# Auth test endpoint
curl http://$BACKEND_URL:8080/api/auth/test

# Register new user
curl -X POST http://$BACKEND_URL:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://$BACKEND_URL:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 3. Check Database

```bash
# Connect to MySQL pod
kubectl exec -it deployment/mysql -n concert-app -- mysql -u concert_user -pconcert_password concert_db

# Inside MySQL shell
SHOW TABLES;
SELECT * FROM users;
SELECT * FROM events;
EXIT;
```

### 4. Monitor Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n concert-app

# MySQL logs
kubectl logs -f deployment/mysql -n concert-app

# All pods in namespace
kubectl logs -f -l tier=application -n concert-app
```

## 🔧 Troubleshooting

### Pod Not Starting

```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n concert-app

# Check pod logs
kubectl logs <pod-name> -n concert-app

# Check previous container logs (if pod restarted)
kubectl logs <pod-name> -n concert-app --previous
```

### MySQL Connection Issues

```bash
# Verify MySQL is running
kubectl get pods -n concert-app -l app=mysql

# Check MySQL service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -n concert-app -- nslookup mysql

# Test MySQL connection
kubectl run mysql-test --rm -it --restart=Never \
  --image=mysql:8.0 \
  --namespace=concert-app \
  --env="MYSQL_PWD=concert_password" \
  -- mysql -h mysql -u concert_user concert_db -e "SELECT 1;"
```

### Backend Not Ready

```bash
# Check backend logs for errors
kubectl logs deployment/backend -n concert-app | grep -i error

# Check environment variables
kubectl exec deployment/backend -n concert-app -- env | grep SPRING

# Check readiness probe
kubectl describe pod <backend-pod-name> -n concert-app | grep -A5 Readiness

# Manually test actuator endpoint
kubectl exec deployment/backend -n concert-app -- curl -s http://localhost:8080/actuator/health
```

### LoadBalancer Pending

```bash
# Check service
kubectl describe service backend -n concert-app

# If on Minikube, use NodePort instead:
kubectl patch service backend -n concert-app -p '{"spec":{"type":"NodePort"}}'

# Or use port-forward for local testing
kubectl port-forward service/backend 8080:8080 -n concert-app
```

### Secrets Not Found

```bash
# List secrets
kubectl get secrets -n concert-app

# Recreate secrets
kubectl delete secret mysql-secret backend-secret -n concert-app
kubectl apply -f k8s/02-mysql-secret.yaml
kubectl apply -f k8s/03-backend-secret.yaml

# Restart deployments to pick up new secrets
kubectl rollout restart deployment/backend -n concert-app
```

### Persistent Volume Issues

```bash
# Check PVC status
kubectl get pvc -n concert-app

# If PVC is Pending, check available storage classes
kubectl get storageclass

# If no storage class, create one (example for local testing):
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

## 📊 Monitoring

### Resource Usage

```bash
# Pod resource usage
kubectl top pods -n concert-app

# Node resource usage
kubectl top nodes

# HPA status
kubectl get hpa -n concert-app -w
```

### Events

```bash
# All events in namespace
kubectl get events -n concert-app --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n concert-app -w
```

### Metrics (if Prometheus installed)

```bash
# Access Prometheus metrics endpoint
kubectl port-forward service/backend 8080:8080 -n concert-app
curl http://localhost:8080/actuator/prometheus
```

## 🔄 Updates and Rollbacks

### Update Backend Image

```bash
# Update deployment with new image
kubectl set image deployment/backend backend=your-registry/concert-backend:v2.0 -n concert-app

# Check rollout status
kubectl rollout status deployment/backend -n concert-app

# Check rollout history
kubectl rollout history deployment/backend -n concert-app
```

### Rollback Deployment

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n concert-app

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n concert-app
```

### Update ConfigMap

```bash
# Edit configmap
kubectl edit configmap backend-config -n concert-app

# Or apply updated file
kubectl apply -f k8s/05-backend-configmap.yaml

# Restart deployment to pick up changes
kubectl rollout restart deployment/backend -n concert-app
```

## 🗑️ Cleanup

### Delete All Resources

```bash
# Delete all resources in namespace
kubectl delete namespace concert-app

# Or delete individually (in reverse order)
kubectl delete -f k8s/12-backend-hpa.yaml
kubectl delete -f k8s/11-ingress.yaml
kubectl delete -f k8s/10-backend-service.yaml
kubectl delete -f k8s/09-backend-deployment.yaml
kubectl delete -f k8s/08-mysql-service.yaml
kubectl delete -f k8s/07-mysql-deployment.yaml
kubectl delete -f k8s/06-mysql-pvc.yaml
kubectl delete -f k8s/05-backend-configmap.yaml
kubectl delete -f k8s/04-mysql-configmap.yaml
kubectl delete -f k8s/03-backend-secret.yaml
kubectl delete -f k8s/02-mysql-secret.yaml
kubectl delete -f k8s/01-namespace.yaml
```

⚠️ **WARNING**: Deleting the namespace will also delete the persistent volume data!

### Backup MySQL Data Before Cleanup

```bash
# Dump database
kubectl exec deployment/mysql -n concert-app -- \
  mysqldump -u concert_user -pconcert_password concert_db > backup.sql

# Or backup persistent volume
kubectl get pvc mysql-pvc -n concert-app -o yaml > mysql-pvc-backup.yaml
```

## 🔐 Production Recommendations

### 1. Use External Secrets Management

- **AWS Secrets Manager** (for EKS)
- **Azure Key Vault** (for AKS)
- **Google Secret Manager** (for GKE)
- **HashiCorp Vault**

```bash
# Example: Create secret from AWS Secrets Manager
kubectl create secret generic backend-secret \
  --from-literal=SPRING_DATASOURCE_PASSWORD="$(aws secretsmanager get-secret-value --secret-id db-password --query SecretString --output text)" \
  --namespace=concert-app
```

### 2. Enable TLS/HTTPS

Update `11-ingress.yaml`:
```yaml
tls:
- hosts:
  - concert.example.com
  secretName: concert-tls
```

Install cert-manager:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```

### 3. Use StatefulSet for MySQL

For production, consider using StatefulSet instead of Deployment for MySQL to ensure stable pod identity and persistent storage.

### 4. Enable Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
  namespace: concert-app
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: mysql
    ports:
    - protocol: TCP
      port: 3306
```

### 5. Configure Resource Limits

Already configured in manifests:
- Backend: 512Mi-1Gi memory, 500m-1000m CPU
- MySQL: 512Mi-1Gi memory, 250m-500m CPU

### 6. Setup Monitoring

- **Prometheus** + **Grafana** for metrics
- **ELK/EFK Stack** for centralized logging
- **Jaeger/Zipkin** for distributed tracing

### 7. Configure Backup Strategy

```bash
# Automated backup cronjob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: concert-app
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            command:
            - /bin/sh
            - -c
            - mysqldump -h mysql -u concert_user -p\$MYSQL_PASSWORD concert_db > /backup/concert_db_\$(date +%Y%m%d).sql
            env:
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: MYSQL_PASSWORD
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
EOF
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)
- [MySQL on Kubernetes](https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## 🆘 Support

For issues or questions:
1. Check troubleshooting section above
2. Review pod logs: `kubectl logs <pod-name> -n concert-app`
3. Check events: `kubectl get events -n concert-app`
4. Review audit report: `docs/BACKEND-INFRASTRUCTURE-AUDIT.md`
