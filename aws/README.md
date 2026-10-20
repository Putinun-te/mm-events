# aws/

Terraform used during the course for the EC2-based deployment: VPC and subnets,
EC2, RDS MySQL, ElastiCache, S3, CloudFront, Cognito, API Gateway, CloudWatch and
IAM. The AWS account it ran in has been closed, so nothing here is live.

- `*.tf`: the infrastructure; copy `terraform.tfvars.example` to
  `terraform.tfvars` to try it in your own account.
- `user_data/backend_setup.sh`: EC2 bootstrap for the backend container.
- `lambda/`, `lambda_presigned_url.py`: Lambda sources for the API Gateway
  routes and S3 presigned uploads.
- `iam_eks_deployment_policy.json`: IAM policy for the EKS deploy user.

To run the app today, use Docker Compose or the free demo (GitHub Pages + Render + Aiven)
described in the main README.
