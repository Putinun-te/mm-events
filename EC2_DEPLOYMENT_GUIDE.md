# EC2 Deployment Guide - Concert Application

## 📋 Overview

This guide provides comprehensive instructions for deploying the Concert application using EC2 instances instead of ECS. This approach is suitable for:
- Development environments
- Testing and staging
- Applications that need direct SSH access
- Cost-optimized deployments
- Easier troubleshooting and debugging

**Key Benefits:**
- ✅ Full SSH access for troubleshooting
- ✅ Direct control over server configuration
- ✅ No container orchestration complexity
- ✅ Easy to monitor and debug
- ✅ Lower cost for small deployments

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     AWS Account                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         VPC: 10.0.0.0/16                         │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │  Public Subnets (us-east-1a, 1b)       │    │  │
│  │  │                                          │    │  │
│  │  │  ┌──────────────┐  ┌──────────────┐   │    │  │
│  │  │  │ Backend EC2  │  │ Frontend EC2 │   │    │  │
│  │  │  │ t3.medium    │  │ t3.medium    │   │    │  │
│  │  │  │ :8080        │  │ :3000        │   │    │  │
│  │  │  └──────────────┘  └──────────────┘   │    │  │
│  │  │                                          │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  │                 ↓                               │  │
│  │  ┌─────────────────────────────────────────┐    │  │
│  │  │   Private Subnets (us-east-1a, 1b)     │    │  │
│  │  │                                          │    │  │
│  │  │   ┌─────────────────────────────────┐  │    │  │
│  │  │   │   RDS MySQL Database            │  │    │  │
│  │  │   │   :3306                         │  │    │  │
│  │  │   └─────────────────────────────────┘  │    │  │
│  │  │                                          │    │  │
│  │  └─────────────────────────────────────────┘    │  │
│  │                                                   │  │
│  └──────────────────────────────────────────────────┘  │
│                      │                                 │
│              ┌───────┴────────┐                        │
│              ↓                ↓                        │
│         [Internet]      [Elastic IPs]                 │
│                                                        │
└─────────────────────────────────────────────────────────┘

External Access:
  - Backend: http://backend-eip:8080
  - Frontend: http://frontend-eip:3000
  - SSH: ssh -i concert-key.pem ubuntu@<eip>
```

---

## 🚀 Quick Start (5 minutes)

### Step 1: Review EC2 Configuration

```bash
cd /Users/putinan/development/DevOps/develop/aws

# View current EC2 settings
grep -A 5 "enable_ec2" terraform.tfvars

# Default configuration:
# enable_ec2_backend = true
# enable_ec2_frontend = true
# ec2_instance_type = "t3.medium"  (2 vCPU, 4GB RAM)
```

### Step 2: Plan Deployment

```bash
# Review what will be created
terraform plan -out=ec2.plan

# Key resources to be created:
# - 2 EC2 instances (backend + frontend)
# - 1 Security group for EC2
# - 1 IAM role + instance profile
# - SSH key pair
# - 2 Elastic IPs
# - CloudWatch log groups
```

### Step 3: Deploy EC2 Infrastructure

```bash
# Apply the Terraform configuration
terraform apply ec2.plan

# Expected output:
# Apply complete! Resources added: 15 (or similar)
# EC2 instances will start in ~2-3 minutes
```

### Step 4: Get Access Information

```bash
# Retrieve connection details
terraform output backend_ec2_ssh_command
terraform output frontend_ec2_ssh_command

# You'll get something like:
# ssh -i concert-key.pem ubuntu@35.123.45.67
```

### Step 5: Deploy Containers

```bash
# Use the deployment helper script
bash ec2-deploy.sh

# Or manually SSH and deploy:
ssh -i concert-key.pem ubuntu@<backend-eip>
docker pull <backend-ecr-url>:latest
docker run -d -p 8080:8080 <backend-ecr-url>:latest
```

---

## 📊 EC2 Deployment Details

### Instance Types & Sizing

#### Option 1: Development (Recommended for Dev)
```hcl
ec2_instance_type   = "t3.micro"        # 1 vCPU, 1GB RAM (free tier eligible)
ec2_root_volume_size = 20               # 20GB storage
# Cost: ~$9/month per instance
```

#### Option 2: Standard (Recommended for Testing)
```hcl
ec2_instance_type   = "t3.small"        # 2 vCPU, 2GB RAM
ec2_root_volume_size = 30               # 30GB storage
# Cost: ~$20/month per instance
```

#### Option 3: Performance (Recommended for Production)
```hcl
ec2_instance_type   = "t3.medium"       # 2 vCPU, 4GB RAM
ec2_root_volume_size = 50               # 50GB storage
# Cost: ~$35/month per instance
```

### Security Groups

**EC2 Security Group Rules:**
```
Inbound:
  • SSH (22)           - from 0.0.0.0/0 (restrict in production)
  • HTTP (80)          - from 0.0.0.0/0
  • HTTPS (443)        - from 0.0.0.0/0
  • Backend (8080)     - from 0.0.0.0/0
  • Frontend (3000)    - from 0.0.0.0/0
  • Docker Registry    - from VPC (10.0.0.0/16)

Outbound:
  • All traffic to 0.0.0.0/0
```

### IAM Permissions

**EC2 instances have access to:**
```
✓ ECR - Pull Docker images
✓ CloudWatch - Send logs
✓ Secrets Manager - Retrieve RDS password
✓ Systems Manager - EC2 Instance Connect (optional)
✗ EC2 describe/terminate (restricted)
```

### SSH Key Management

```bash
# Key file location and permissions
ls -la /Users/putinan/development/DevOps/develop/aws/concert-key.pem
# -rw------- 1 user group 1704 date time concert-key.pem

# SSH connection example
ssh -i concert-key.pem ubuntu@<instance-ip>

# If permissions are wrong
chmod 600 concert-key.pem

# SSH options for first-time connection
ssh -i concert-key.pem \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    ubuntu@<instance-ip>
```

---

## 📦 Container Deployment on EC2

### Manual Deployment Steps

#### 1. SSH to Backend Instance

```bash
BACKEND_EIP=$(terraform output -raw backend_ec2_eip)
ssh -i concert-key.pem ubuntu@$BACKEND_EIP
```

#### 2. Setup Docker & AWS Credentials

```bash
# Docker is pre-installed by user data script
docker --version

# Setup AWS CLI credentials (or use IAM role)
aws configure
# AWS Access Key ID: <your-key>
# AWS Secret Access Key: <your-secret>
# Default region: us-east-1
```

#### 3. Login to ECR

```bash
# Get credentials
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

#### 4. Pull & Run Backend Image

```bash
# Pull backend image from ECR
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest

# Run backend container
docker run -d \
  --name concert-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -e MYSQL_HOST=concert-db.xxxxx.us-east-1.rds.amazonaws.com \
  -e MYSQL_PORT=3306 \
  -e MYSQL_DB=concert \
  -e MYSQL_USER=admin \
  -e MYSQL_PASSWORD=$(aws secretsmanager get-secret-value \
      --secret-id concert-rds-password \
      --query SecretString --output text) \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest

# Verify container is running
docker ps -a
docker logs concert-backend
```

#### 5. Similar for Frontend (port 3000)

```bash
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-frontend:latest

docker run -d \
  --name concert-frontend \
  --restart unless-stopped \
  -p 3000:3000 \
  -e API_URL=http://<backend-eip>:8080 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/concert/concert-frontend:latest
```

### Using Deployment Helper Script

```bash
cd aws

# Make script executable
chmod +x ec2-deploy.sh

# Run interactive menu
./ec2-deploy.sh

# Select option 4 to deploy backend
# Select option 5 to deploy frontend
```

---

## 🔗 Accessing Your Application

### Frontend Access
```bash
# Get frontend EIP
FRONTEND_EIP=$(terraform output -raw frontend_ec2_eip)

# Open in browser
open "http://$FRONTEND_EIP:3000"

# Or
curl "http://$FRONTEND_EIP:3000"
```

### Backend API Access
```bash
# Get backend EIP
BACKEND_EIP=$(terraform output -raw backend_ec2_eip)

# Test backend health
curl "http://$BACKEND_EIP:8080/api/auth/test"

# Login example
curl -X POST "http://$BACKEND_EIP:8080/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"user","password":"pass"}'
```

### SSH Access

```bash
# Get SSH command from Terraform
terraform output backend_ec2_ssh_command

# Or manually
BACKEND_EIP=$(terraform output -raw backend_ec2_eip)
ssh -i concert-key.pem ubuntu@$BACKEND_EIP

# Once connected
ubuntu@ip-10-0-1-xxx:~$ docker ps
ubuntu@ip-10-0-1-xxx:~$ docker logs concert-backend
ubuntu@ip-10-0-1-xxx:~$ docker exec -it concert-backend bash
```

---

## 📊 Monitoring & Troubleshooting

### Check EC2 Instance Status

```bash
# Using AWS CLI
aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
  --output table

# Output:
# |  i-0abc123def456ghi  |  running  |  35.123.45.67  |
# |  i-0xyz789abc123def  |  running  |  54.234.56.78  |
```

### View CloudWatch Logs

```bash
# Docker logs
aws logs tail /concert/ec2/docker --follow

# System logs
aws logs tail /concert/ec2/system --follow

# Specific instance
aws logs tail /concert/ec2/docker \
  --follow \
  --log-stream-name $(terraform output -raw backend_ec2_instance_id)
```

### SSH Troubleshooting

```bash
# Can't connect to instance
# 1. Check instance is running
aws ec2 describe-instance-status --instance-ids i-xxxxx

# 2. Check security group allows SSH (port 22)
aws ec2 describe-security-groups --group-ids sg-xxxxx

# 3. Check key permissions
chmod 600 concert-key.pem

# 4. Try with verbose mode
ssh -v -i concert-key.pem ubuntu@<ip>
```

### Container Issues

```bash
# SSH to instance
ssh -i concert-key.pem ubuntu@<backend-eip>

# Check Docker status
docker ps -a
docker logs concert-backend

# Restart container
docker restart concert-backend

# Remove and restart
docker rm -f concert-backend
docker run -d ... # re-run container

# Check logs
docker logs --tail 50 concert-backend
```

---

## 💾 Backup & Recovery

### Backup EC2 Instances

```bash
# Create AMI from running instance
aws ec2 create-image \
  --instance-id i-xxxxx \
  --name "concert-backend-backup-$(date +%Y%m%d)" \
  --description "Backup of backend instance"

# Create EBS snapshots
aws ec2 create-snapshot \
  --volume-id vol-xxxxx \
  --description "Backup of backend volume"
```

### Restore from Backup

```bash
# Launch new instance from AMI
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t3.medium \
  --key-name concert-deployer-key
```

---

## 🔒 Security Best Practices

### 1. Restrict SSH Access
```hcl
# In ec2.tf, modify security group
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Your IP only
}
```

### 2. Use Secrets Manager
```bash
# Retrieve DB password securely
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id concert-rds-password \
  --query SecretString --output text)
```

### 3. Enable CloudWatch Monitoring
```bash
# Logs are automatically sent to CloudWatch
# Monitor from AWS Console or CLI
aws logs tail /concert/ec2/ --follow
```

### 4. Implement Auto-Restart
```bash
# Docker containers have --restart unless-stopped
# Ensures containers restart on failure or reboot

# Manual check
docker inspect concert-backend | grep -A 5 "RestartPolicy"
```

---

## 📈 Scaling EC2 Deployment

### Horizontal Scaling (Add More Instances)

```hcl
# Scale by creating multiple instances
# Modify variables.tf

variable "backend_instance_count" {
  default = 1
}

# Then in ec2.tf, use count
resource "aws_instance" "backend" {
  count = var.backend_instance_count
  ...
}
```

### Load Balancing (Multiple Instances)

```bash
# Option 1: Use ALB (Application Load Balancer)
# Already configured in Terraform

# Option 2: Use NLB (Network Load Balancer)
# Modify main.tf to use NLB instead

# Option 3: DNS round-robin
# Create DNS records pointing to both instance IPs
```

### Cost Optimization

```hcl
# Use reserved instances for 1-year commitment
# Use spot instances for non-critical workloads
# Auto-stop instances when not needed
# Consider using smaller instance types

variable "use_spot_instances" {
  default = false
}

variable "use_reserved_instances" {
  default = true
}
```

---

## 🔄 Updating Applications

### Method 1: Stop/Start Container

```bash
# SSH to instance
ssh -i concert-key.pem ubuntu@<eip>

# Stop current container
docker stop concert-backend

# Pull new image
docker pull <ecr-url>:latest

# Start new container
docker run -d ... (with new image)
```

### Method 2: Blue/Green Deployment

```bash
# Run new version on different port
docker run -d \
  --name concert-backend-new \
  -p 8081:8080 \
  <new-image-url>

# Test new version
curl http://localhost:8081/api/auth/test

# If OK, switch traffic and remove old
docker stop concert-backend
docker rm concert-backend
docker rename concert-backend-new concert-backend
```

### Method 3: Rolling Update

```bash
# For multiple instances, update one at a time
# Update instance 1 while 2,3,4 handle traffic
# Wait for health checks
# Move to instance 2, etc.
```

---

## 📋 Terraform Commands Reference

```bash
# Plan only EC2 changes
terraform plan -target=aws_instance.backend -target=aws_instance.frontend

# Apply only EC2 changes
terraform apply -target=aws_instance.backend -target=aws_instance.frontend

# Destroy only EC2 instances (keep VPC, RDS, etc.)
terraform destroy -target=aws_instance.backend -target=aws_instance.frontend

# Refresh state without changes
terraform refresh

# Get all outputs
terraform output

# Get specific output
terraform output -raw backend_ec2_ssh_command
```

---

## ❌ Troubleshooting Common Issues

### Issue: "ServiceUnavailable" when connecting
**Solution:**
```bash
# Instance might still be initializing
# Wait 2-3 minutes for user data script to complete
# Check system log in AWS Console
# Verify security group allows traffic
```

### Issue: "Permission denied (publickey)"
**Solution:**
```bash
# Fix key permissions
chmod 600 concert-key.pem

# Verify key is correct
ssh-keygen -l -f concert-key.pem

# Check instance has public IP
aws ec2 describe-instances --instance-ids i-xxxxx
```

### Issue: "Docker: permission denied"
**Solution:**
```bash
# User needs to be in docker group
# This is done automatically by user data script
# If missing, run:
sudo usermod -aG docker ubuntu
newgrp docker
```

### Issue: "Can't pull from ECR"
**Solution:**
```bash
# Verify IAM role has ECR permissions
# Check AWS credentials are configured
aws ecr get-login-password --region us-east-1

# Re-login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
```

---

## 📞 Getting Help

### Useful Commands

```bash
# Get all instance info
terraform output | grep ec2

# Monitor logs
aws logs tail /concert/ec2/ --follow

# Check instance CPU/memory
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxxxx \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-01T01:00:00Z \
  --period 300 \
  --statistics Average

# SSH with debug info
ssh -vvv -i concert-key.pem ubuntu@<ip>
```

### Quick Reference

| Task | Command |
|------|---------|
| Deploy | `terraform apply -auto-approve` |
| Destroy | `terraform destroy -auto-approve` |
| SSH Backend | `ssh -i concert-key.pem ubuntu@$(terraform output -raw backend_ec2_eip)` |
| SSH Frontend | `ssh -i concert-key.pem ubuntu@$(terraform output -raw frontend_ec2_eip)` |
| View Logs | `aws logs tail /concert/ec2/ --follow` |
| Check Status | `aws ec2 describe-instances --region us-east-1` |
| Get Backend URL | `terraform output -raw backend_ec2_public_ip` |
| Get Frontend URL | `terraform output -raw frontend_ec2_public_ip` |

---

## 📚 Additional Resources

- [Terraform AWS EC2 Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Documentation](https://docs.docker.com/)
- [ECR Documentation](https://docs.aws.amazon.com/ecr/)

---

**Last Updated:** October 30, 2025  
**Status:** Complete EC2 deployment solution ready  
**Next Steps:** Execute `terraform apply` to deploy EC2 instances
