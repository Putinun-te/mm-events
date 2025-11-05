# Serverless Free-Tier Optimized Stack

This Terraform stack replaces the EC2 auto scaling architecture with a pay-per-request, mostly-free-tier friendly design using managed services. The layout keeps operating costs low while preserving the ability to scale when traffic increases.

## What Gets Deployed
- **Amazon Cognito** user pool and app client for sign-up/sign-in (optional hosted domain).
- **Amazon API Gateway (HTTP)** fronting a **Lambda** function that runs your API container or zip package.
- **Amazon RDS MySQL** `db.t3.micro` (default 8.0.36) with encrypted storage, autoscaling up to 100 GB, and credentials stored in **Secrets Manager**.
- **Amazon EFS One Zone** with lifecycle policy to move inactive files to Infrequent Access, exposed through an access point for Lambda.
- **Amazon S3** bucket for durable media/object storage with Intelligent-Tiering after 30 days.
- **Amazon ElastiCache Serverless (Redis)** (opt-in) for low-latency caching; enable by setting `enable_elasticache = true`.
- **CloudWatch Alarms & Dashboard** (opt-in) watching Lambda errors, API Gateway 5XXs, and RDS CPU with optional SNS notifications.
- **VPC** with two AZs, isolated private subnets, interface endpoints for Secrets Manager and CloudWatch, and a gateway endpoint for S3 (no NAT needed).

## Cost Guardrails
- Lambda starts at 1 GB memory and scales automatically; set `lambda_timeout`, `lambda_memory_size`, and concurrency limits in code if needed.
- RDS uses a single `db.t3.micro`; set `db_multi_az = true` only if redundancy is required (it doubles the cost).
- EFS One Zone + lifecycle to IA keeps active storage < 10 GB cheap; archive cold media back to S3 IA or Glacier via your app.
- S3 lifecycle defaults to Intelligent-Tiering; adjust to Deep Archive if long-term retention is required.
- Redis serverless charges only for data + throughput you actually use; cap utilization with `redis_max_data_storage_gb` and `redis_max_ecpu_per_second` to stay inside budget.
- No NAT Gateway or load balancer costs. VPC endpoints cover Secrets Manager and Logs so Lambda can stay inside private subnets.

## Prerequisites
1. Terraform 1.5+ and AWS credentials (the config expects `aws sso login` or an IAM user with administrator access during bootstrap).
2. A deployed Lambda artifact:
   - **Container image** pushed to ECR (`lambda_package_type = "Image"`, provide `lambda_image_uri`).
   - **Zip bundle** stored locally (`lambda_package_type = "Zip"`, provide `lambda_deployment_package_path`, `lambda_runtime`, and `lambda_handler`).
3. Globally unique S3 bucket name ready (`s3_bucket_name`).
4. Decide on Cognito hosted domain prefix (optional).

## Quick Start
```bash
cd infra/terraform/serverless
terraform init
terraform plan \
  -var "project_name=concert" \
  -var "environment=prod" \
  -var "s3_bucket_name=concert-event-media-<unique>" \
  -var "lambda_image_uri=<account>.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest" \
  -var "cognito_callback_urls=[\"https://app.example.com/callback\"]" \
  -var "cognito_logout_urls=[\"https://app.example.com/logout\"]" \
  -var "enable_elasticache=true"
terraform apply
```

### Important Parameters
- `project_name` and `environment` drive resource names and tagging.
- `lambda_package_type` switches between container and zip flows.
- `lambda_environment_overrides` lets you pass additional env vars (e.g. feature flags).
- `db_*` variables tune RDS (storage, retention, monitoring). Leave defaults for free-tier alignment.
- `s3_lifecycle_rules` can be overridden if you want deeper archival tiers.
- `enable_elasticache` toggles the Redis cache. When enabled, `REDIS_ENDPOINT` and `REDIS_PORT` are injected into Lambda environment variables and `elasticache:Connect` permission is added automatically.
- `enable_cloudwatch_alarms` + `cloudwatch_alarm_actions` let you wire SNS/email for operational alerts, and `enable_cloudwatch_dashboard` publishes a ready-to-use dashboard.

### Outputs
After `terraform apply`, note the values in the output:
- `api_endpoint`: Base URL for your API Gateway stage.
- `cognito_user_pool_id` / `cognito_app_client_id`: configure the frontend auth client.
- `s3_bucket_name`: upload destination for media.
- `rds_endpoint` and `rds_secret_arn`: application uses the secret to connect.
- `efs_access_point_arn`: referenced by the Lambda mount configuration.
- `redis_endpoint`: hostname:port for Redis when caching is enabled.
- `cloudwatch_dashboard_name`: name of the prebuilt dashboard (useful for quick sharing).

## Deployment Pipeline Tips
1. Build and push the Lambda image from CI before running Terraform. A sample GitHub Actions step:
   ```yaml
   - name: Log in to ECR
     run: aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
   - name: Build and push
     run: |
       docker build -t concert-api .
       docker tag concert-api:latest ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest
       docker push ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com/concert-api:latest
   ```
2. Use Terraform Cloud, Atlantis, or GitHub Actions with OIDC for deployment automation. Restrict applies to release branches.
3. Configure AWS Budgets alerts at $100/month (or lower) and enable Cost Anomaly Detection for compute + storage categories.

## Cleanup
Run the standard Terraform destroy when you no longer need the stack:
```bash
terraform destroy -var "project_name=concert" -var "environment=prod" -var "s3_bucket_name=concert-event-media-<unique>"
```
Because the bucket was created with `force_destroy = true`, Terraform empties it automatically. RDS is configured to skip the final snapshot by default; change `db_skip_final_snapshot = false` if you need a backup before teardown.

## Roadmap / Extensions
- Add EventBridge Scheduler to stop/start RDS overnight.
- Attach CloudFront once budget allows for global caching and TLS.
- Add AWS Backup plan for RDS and EFS if long-term retention is needed.
- Integrate WAF on API Gateway if you need additional request filtering.
- Layer in Elastic Beanstalk or App Runner only if you move away from Lambda; current stack already runs Docker-based Lambda images with managed HTTPS (API Gateway provides TLS out of the box, custom domains require an ACM certificate).
