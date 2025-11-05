# Concert Production Infrastructure

Cost-optimized serverless stack with HTTPS (API Gateway), security groups, and IAM management.

## Architecture
- **API Gateway HTTP API** (HTTPS by default, custom domain optional with ACM certificate)
- **Lambda** (container) + VPC + EFS mount for event/avatar pictures
- **RDS MySQL** db.t3.micro with Secrets Manager credentials
- **ElastiCache Serverless Redis** (optional caching layer)
- **S3** for static/media storage (versioning off, Intelligent-Tiering lifecycle)
- **EFS One Zone** with IA lifecycle for shared picture storage
- **Cognito** user pool for authentication
- **CloudWatch** alarms + dashboard for monitoring
- **VPC** with private subnets, interface endpoints (Secrets Manager, Logs), S3 gateway endpoint (no NAT)
- **Security Groups** for Lambda, RDS, EFS, ElastiCache

## Prerequisites
1. AWS CLI configured (`aws configure` or `aws sso login`)
2. Terraform 1.5+
3. Docker image pushed to ECR:
   ```bash
   aws ecr create-repository --repository-name concert-api --region us-east-1
   docker build -t concert-api:latest ../../main_backend
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
   docker tag concert-api:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest
   docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest
   ```

## Deployment
```bash
cd infra/terraform/production

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply

# Outputs will show:
# - api_endpoint (HTTPS URL)
# - cognito_user_pool_id
# - cognito_app_client_id
# - rds_endpoint
# - s3_bucket_name
# - redis_endpoint
# - efs_access_point_arn
```

## HTTPS / Custom Domain
**API Gateway provides HTTPS out of the box** at the default `execute-api` URL. For a custom domain:
1. Request ACM certificate in `us-east-1` for your domain
2. Validate via DNS/email
3. Create API Gateway custom domain mapping to the certificate
4. Point your DNS CNAME/ALIAS to the API Gateway domain name

No CloudFront needed for HTTPS—API Gateway terminates TLS automatically.

## Security Features
- All traffic in private subnets (Lambda → RDS/EFS/ElastiCache)
- VPC endpoints avoid NAT Gateway costs and internet exposure
- Security groups restrict access (Lambda ↔ RDS, EFS, Redis)
- RDS encrypted at rest, credentials in Secrets Manager
- S3 public access blocked, presigned URLs via Lambda
- EFS encrypted at rest
- Cognito JWT tokens validated by API Gateway authorizer

## IAM Groups
Run the IAM group maintenance script to preserve user memberships:
```bash
cd ../../aws
chmod +x iam-group-maintenance.sh

# Before destroying old infrastructure
./iam-group-maintenance.sh detach

# After deploying new infrastructure (recreates groups with policies)
./iam-group-maintenance.sh provision
```

Groups created:
- `concert-prod-admins` → AdministratorAccess
- `concert-prod-developers` → PowerUserAccess
- `concert-prod-testers` → ReadOnlyAccess
- `concert-prod-deployment` → PowerUserAccess + PassRole + self-service policies

## Cost Optimization ($150 for 3-4 months)
- **Lambda**: Pay per request (1M free requests/month, then $0.20/1M)
- **RDS t3.micro**: ~$15/month (750 hrs free tier first 12 months)
- **EFS One Zone + IA**: ~$0.16/GB-month for IA tier (keep <10 GB)
- **ElastiCache Serverless**: Pay for data + throughput used (set caps in variables)
- **S3**: First 5 GB free, then $0.023/GB
- **API Gateway**: 1M free calls/month, then $1/million
- **No NAT Gateway** ($32+/month saved by using VPC endpoints)
- **No ALB** ($16+/month saved by using API Gateway)

Estimated monthly cost: **$20-30** with moderate traffic.

Set up AWS Budgets alarm at $50/month and Cost Anomaly Detection for safety.

## Cleanup
```bash
terraform destroy
```

S3 bucket auto-empties (`force_destroy = true`). RDS skips final snapshot by default.

## Monitoring
- CloudWatch dashboard: `concert-prod-overview`
- Alarms: Lambda errors, API 5XX, RDS CPU
- Logs: `/aws/lambda/concert-prod-api`, `concert-prod-api-execution`

## Scaling
- Lambda auto-scales to traffic (set reserved concurrency if needed)
- RDS storage auto-scales to 100 GB
- ElastiCache serverless auto-scales within configured limits
- EFS auto-scales

## Troubleshooting
- **Lambda timeout**: Increase `lambda_timeout` (default 30s)
- **RDS connections**: Enable RDS Proxy if >100 concurrent Lambda invocations
- **EFS mount errors**: Check security group allows Lambda → EFS on port 2049
- **Redis connection**: Verify Lambda security group can reach ElastiCache on port 6379
- **API 403 Forbidden**: Check Cognito JWT authorizer configuration
