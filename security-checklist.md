# Security Configuration Checklist

## Before Deployment - Always Check:

### 1. EKS Security Groups
- [ ] EKS cluster security group allows worker nodes
- [ ] Worker nodes can communicate with each other
- [ ] ALB can reach worker nodes on port 8080

### 2. RDS Security Groups  
- [ ] RDS allows EKS worker nodes on port 3306
- [ ] RDS blocks public internet access
- [ ] Only specific subnets can access RDS

### 3. S3 Bucket Policies
- [ ] CloudFront can access S3 bucket
- [ ] Public read access for static files
- [ ] Block public write access

### 4. ALB/LoadBalancer
- [ ] ALB security group allows HTTP/HTTPS from internet
- [ ] ALB can reach backend pods
- [ ] Health checks configured properly

### 5. VPC Configuration
- [ ] Subnets in different AZs
- [ ] Private subnets for RDS
- [ ] Public subnets for ALB
- [ ] Route tables configured

## Auto-Fix Script
Run before any deployment:
```bash
./fix-all-security.sh
```