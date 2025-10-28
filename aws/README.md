# AWS Deployment with Terraform

This directory contains Terraform configuration for deploying the Concert application to AWS using ECS (Elastic Container Service) on Fargate.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                             │
└─────────────────────────────┬───────────────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │   ALB (Port 80)    │
                    └─────────┬──────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
         ┌──────────▼──────────┐  ┌──────▼──────────┐
         │  Frontend Service   │  │ Backend Service │
         │   (Fargate x2)      │  │  (Fargate x2)   │
         │   Port: 3000        │  │  Port: 8080     │
         └──────────┬──────────┘  └──────┬──────────┘
                    │                    │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │   RDS MySQL 8.0    │
                    │   Multi-AZ: False  │
                    └────────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **Docker** images pushed to ECR (see below)

## Setup Instructions

### 1. Clone and Setup

```bash
cd aws/
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure terraform.tfvars

Edit `terraform.tfvars` with your values:

```bash
# Update these critical values:
db_password = "YourSecurePassword123!"  # Change to a strong password!
backend_image_uri = "YOUR_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/concert/concert-backend:latest"
frontend_image_uri = "YOUR_AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/concert/concert-frontend:latest"
```

### 3. Build and Push Docker Images to ECR

First, get your AWS account ID:
```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-1
```

Create ECR repositories:
```bash
aws ecr create-repository --repository-name concert/concert-backend --region $AWS_REGION
aws ecr create-repository --repository-name concert/concert-frontend --region $AWS_REGION
```

Login to ECR:
```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

Build and push backend:
```bash
cd ../main_backend
docker build -f Dockerfile.k8s -t concert-backend:latest .
docker tag concert-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/concert/concert-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/concert/concert-backend:latest
cd ../aws
```

Build and push frontend:
```bash
cd ../main_frontend/concert1
docker build -f Dockerfile.k8s -t concert-frontend:latest .
docker tag concert-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/concert/concert-frontend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/concert/concert-frontend:latest
cd ../../aws
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Plan the Deployment

```bash
terraform plan -out=tfplan
```

Review the plan carefully to ensure all resources are correct.

### 6. Apply the Configuration

```bash
terraform apply tfplan
```

This will create:
- VPC with public and private subnets
- NAT Gateways for private subnet outbound traffic
- Application Load Balancer
- ECS Cluster with Fargate launch type
- RDS MySQL database
- ECR repositories
- CloudWatch log groups
- Auto Scaling policies

### 7. Access the Application

After deployment, terraform will output the application URL:

```bash
terraform output application_url
```

Open this URL in your browser. The backend is accessible at `/api/...` paths.

## Monitoring and Maintenance

### View ECS Logs

```bash
# View recent logs
aws logs tail /ecs/concert --follow

# View specific service logs
aws logs tail /ecs/concert --follow --filter-pattern "backend"
```

### Check Service Status

```bash
aws ecs describe-services \
  --cluster concert-cluster \
  --services concert-backend-service concert-frontend-service \
  --query 'services[*].[serviceName,status,runningCount,desiredCount]'
```

### Scale Services Manually

```bash
# Scale backend to 3 tasks
aws ecs update-service \
  --cluster concert-cluster \
  --service concert-backend-service \
  --desired-count 3
```

### Update Task Definition

When you push new Docker images, create a new task definition revision:

```bash
# Update the image in terraform.tfvars, then:
terraform apply
```

### View Auto Scaling Metrics

```bash
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id service/concert-cluster/concert-backend-service
```

## Database Access

### Connect to RDS from Local Machine

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint | cut -d: -f1)

# Using mysql client
mysql -h $RDS_ENDPOINT -u concert_user -p concert_db
```

### Create a Bastion Host (Optional but Recommended for Production)

For production, create an EC2 bastion host in a public subnet to access RDS securely.

## Destroying Resources

**WARNING: This will delete all resources including the RDS database!**

```bash
# Plan the destruction
terraform plan -destroy

# Actually destroy
terraform destroy
```

To keep the RDS database:
```bash
terraform destroy -target=aws_ecs_service.backend -target=aws_ecs_service.frontend
# Then manually delete ECS services if needed
```

## Cost Estimation

Approximate monthly costs (US East 1, dev environment):
- **ECS Fargate**: ~$40-50 (2 backend + 2 frontend tasks)
- **RDS MySQL t3.micro**: ~$10
- **ALB**: ~$20
- **NAT Gateway**: ~$35
- **Data Transfer**: ~$5-15
- **Total**: ~$110-130/month

Use `terraform plan` to see detailed pricing before deploying.

## Troubleshooting

### Services not becoming healthy

Check the target group health:
```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]'
```

### Database connection issues

1. Verify RDS is running: `aws rds describe-db-instances`
2. Check security groups: `aws ec2 describe-security-groups`
3. Check ECS task logs: `aws logs tail /ecs/concert --follow`

### Container not starting

Check task definition and logs:
```bash
# Get task ARN
TASK_ARN=$(aws ecs list-tasks --cluster concert-cluster | jq -r '.taskArns[0]')

# Describe task
aws ecs describe-tasks --cluster concert-cluster --tasks $TASK_ARN

# View logs
aws logs tail /ecs/concert --follow
```

## Environment Variables

### Backend Environment Variables

- `SPRING_DATASOURCE_URL`: RDS connection string
- `SPRING_DATASOURCE_USERNAME`: Database user
- `SPRING_DATASOURCE_PASSWORD`: Database password (from Secrets Manager)
- `SPRING_JPA_HIBERNATE_DDL_AUTO`: Set to 'update' for auto schema updates
- `SPRING_PROFILES_ACTIVE`: Set to 'aws'
- `JAVA_OPTS`: JVM memory settings

### Frontend Environment Variables

- `NODE_ENV`: Environment (dev/staging/prod)

## Security Best Practices

1. **Always use strong database passwords** (at least 16 characters, mixed case, numbers, symbols)
2. **Enable RDS encryption** at rest (set `storage_encrypted = true`)
3. **Use Secrets Manager** for sensitive data (already configured)
4. **Enable VPC Flow Logs** for network monitoring
5. **Use HTTPS** with ACM certificate (requires additional configuration)
6. **Implement WAF** for the ALB in production
7. **Enable CloudTrail** for audit logging
8. **Regularly update** Docker images and dependencies

## Advanced Configuration

### Multi-AZ RDS (Production)

```hcl
db_multi_az = true
```

### Enable HTTPS/TLS

Add to `main.tf`:
```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.concert.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.concert.arn
  # ... redirect HTTP to HTTPS
}
```

### Enable RDS Enhanced Monitoring

```hcl
enabled_cloudwatch_logs_exports = ["error", "general", "slowquery", "audit"]
```

## File Structure

```
aws/
├── main.tf              # Core infrastructure (VPC, ALB, RDS, ECS)
├── ecs.tf               # ECS task definitions and services
├── secrets.tf           # AWS Secrets Manager configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values (create from .example)
├── terraform.tfvars.example  # Example configuration
└── README.md            # This file
```

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [ECS Fargate Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)
- [RDS MySQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Check ECS task status
4. Review Terraform apply output

---

**Last Updated:** October 28, 2025  
**Version:** 1.0
