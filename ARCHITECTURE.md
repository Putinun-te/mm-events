# 🏗️ Production Architecture

## Recommended Setup

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    CloudFront (CDN)                          │
│  - Global edge locations                                     │
│  - HTTPS/SSL                                                 │
│  - Caching                                                   │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────┐   ┌───────────────────────────────┐
│   S3 Bucket            │   │   Application Load Balancer   │
│   (Frontend - Nuxt)    │   │   (Backend - Spring Boot)     │
│   - Static files       │   │   - /api/* routes             │
│   - index.html         │   │   - Health checks             │
└────────────────────────┘   └───────────┬───────────────────┘
                                         │
                                         ▼
                             ┌───────────────────────────────┐
                             │   EKS Cluster (Singapore)     │
                             │   - Backend pods              │
                             │   - Auto-scaling              │
                             │   - t4g.medium nodes          │
                             └───────────┬───────────────────┘
                                         │
                                         ▼
                             ┌───────────────────────────────┐
                             │   RDS MySQL                   │
                             │   - Database                  │
                             │   - Automated backups         │
                             └───────────────────────────────┘
```

## Components

### Frontend (S3 + CloudFront)
- **S3**: Hosts static Nuxt build files
- **CloudFront**: CDN for fast global delivery
- **Cost**: ~$1-5/month

### Backend (EKS)
- **EKS Cluster**: Runs Spring Boot API
- **ALB**: Routes traffic to backend pods
- **Auto-scaling**: 2-4 nodes based on load
- **Cost**: ~$60-120/month

### Database (RDS)
- **MySQL 8.0**: Production database
- **Multi-AZ**: High availability
- **Cost**: ~$30-50/month

### CI/CD (GitHub Actions on EKS)
- **Self-hosted runners**: Run on EKS cluster
- **Cost**: Included in EKS cost

## Deployment Scripts

```bash
# 1. Deploy Frontend
./deploy-frontend-s3-cloudfront.sh

# 2. Backend is already on EKS
kubectl get pods

# 3. Setup CI/CD
./setup-github-runners.sh
```

## Total Monthly Cost
- **Minimal**: ~$90/month (1 node, small RDS)
- **Recommended**: ~$150/month (2 nodes, standard RDS)
- **Production**: ~$300/month (4 nodes, Multi-AZ RDS)
