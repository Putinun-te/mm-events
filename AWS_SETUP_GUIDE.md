# AWS Account Setup Guide

Complete step-by-step guide to configure your AWS account and deploy the Concert application.

## 🔐 Step 1: Get AWS Credentials

### From AWS Console:
1. Go to https://console.aws.amazon.com
2. Click your account name (top right) → **Security Credentials**
3. Click **Access Keys** → **Create access key**
4. Choose **CLI** as use case
5. Save your **Access Key ID** and **Secret Access Key**
6. ⚠️ **IMPORTANT**: Store these securely - never commit to git!

## 🛠️ Step 2: Configure AWS CLI

Run this command and enter your credentials:

```bash
aws configure
```

**When prompted, enter:**
- AWS Access Key ID: `Your_Access_Key_ID_Here`
- AWS Secret Access Key: `Your_Secret_Key_Here`
- Default region: `us-east-1` (or your preferred region)
- Default output format: `json`

Verify it worked:
```bash
aws sts get-caller-identity
```

Should output your Account ID, User ARN, and UserId.

## 🚀 Step 3: Deploy to AWS (5 minutes)

### 3.1 Navigate to the aws directory

```bash
cd aws
```

### 3.2 Configure Terraform variables

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Must update these values:**

```hcl
# AWS region where resources will be created
aws_region = "us-east-1"

# A database password - make it strong!
# Example: "Cw2@9pL#x8K$vQ1!mN4&bF5"
db_password = "YourStrongPassword123!"

# Your Docker image URIs (we'll generate these)
backend_image_uri = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest"
frontend_image_uri = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/concert/concert-frontend:latest"

# Application environment
app_environment = "dev"  # or "prod"

# Auto-scaling settings
backend_min_tasks = 2
backend_max_tasks = 4
frontend_min_tasks = 2
frontend_max_tasks = 4
```

### 3.3 Create Docker images and push to ECR

```bash
# Build and push images (requires Docker running)
make aws-build-all
```

This will:
- Build the backend Docker image
- Build the frontend Docker image
- Create ECR repositories if needed
- Push images to AWS ECR

### 3.4 Initialize Terraform

```bash
# Download Terraform providers
terraform init
```

This creates a `.terraform` directory with required plugins.

### 3.5 Review what will be created

```bash
# See the deployment plan
terraform plan

# Save the plan to a file (optional)
terraform plan -out=tfplan
```

Review the output carefully. It should show:
- VPC with subnets
- Application Load Balancer
- ECS cluster and services
- RDS database
- Security groups
- IAM roles

### 3.6 Deploy to AWS

```bash
# Create all AWS resources
terraform apply

# If you saved a plan, use it:
terraform apply tfplan
```

This will take 5-10 minutes. When complete, you'll see outputs including:
- **alb_dns_name**: The URL to access your application
- **rds_endpoint**: Your database endpoint
- **backend_ecr_uri**: Backend image repository

## ✅ Step 4: Verify Deployment

```bash
# Check if services are running
make status

# View application logs
make logs

# Check database health
make monitor-rds
```

Once services are running, open the ALB DNS name in your browser. You should see the Concert application!

## 🔍 Troubleshooting

### "Access Denied" errors
- Verify AWS credentials: `aws sts get-caller-identity`
- Check IAM permissions - you need admin or broad EC2, ECS, RDS permissions

### "Resource limit exceeded" or quota errors
- Check available capacity: `aws ec2 describe-account-attributes`
- Some regions have lower defaults; try `us-east-1` or `us-west-2`

### ECR push fails
- Verify Docker is running: `docker ps`
- Check authentication: `aws ecr get-login-password --region us-east-1 | docker login ...`

### Terraform init fails
- Clear cache: `rm -rf .terraform`
- Verify Terraform installation: `terraform version`

## 💰 Cost Optimization

To reduce costs:
- Use `app_environment = "dev"` for lower specs
- Set `backend_min_tasks = 1` and `frontend_min_tasks = 1`
- Stop resources when not in use

To stop (don't delete):
```bash
# Scale down services
aws ecs update-service --cluster concert-ecs --service concert-backend --desired-count 0
aws ecs update-service --cluster concert-ecs --service concert-frontend --desired-count 0

# Stop RDS
aws rds stop-db-instance --db-instance-identifier concert-db
```

To delete everything (WARNING - cannot recover):
```bash
terraform destroy
```

## 📚 Helpful Commands

```bash
# Show all available make targets
make help

# Get application status
make status

# Follow live logs
make logs

# Monitor RDS database
make monitor-rds

# Scale backend service
aws ecs update-service --cluster concert-ecs --service concert-backend --desired-count 3

# SSH into container (for debugging)
aws ecs execute-command --cluster concert-ecs --task TASK_ID --container concert-backend --interactive --command "/bin/bash"
```

## 🔐 Security Notes

- ✅ Store `terraform.tfvars` in `.gitignore` (never commit credentials)
- ✅ Use strong database password (32+ chars with special chars)
- ✅ Enable AWS CloudTrail for audit logging
- ✅ Rotate access keys periodically
- ✅ Delete test resources when done
- ⚠️ ALB is public - consider adding authentication for production

## 📞 Getting Help

If deployment fails:
1. Check CloudWatch logs: `make logs`
2. Review Terraform state: `terraform state list`
3. Check AWS Console for resource errors
4. Read `aws/README.md` for detailed documentation

---

**Done?** Your Concert application is now running on AWS! 🎉
