# S3 + CloudFront Frontend Hosting

This document explains how to host the frontend as a static site in S3 and serve it via CloudFront.

Prerequisites
- AWS CLI configured with credentials
- Terraform installed and initialized in `aws/`
- `jq` installed (optional, for nicer output)

Quick steps

1. Deploy S3 + CloudFront via Terraform

```bash
cd /Users/putinan/development/DevOps/develop/aws
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

2. Build/prepare your frontend static files

- If your frontend builds to `../main_frontend/concert1/dist` use that; if it uses `.output` adjust accordingly.

3. Sync files to S3

```bash
# from repository root
cd /Users/putinan/development/DevOps/develop/aws
make s3-sync
```

4. Invalidate CloudFront cache (optional)

```bash
make cf-invalidate
```

5. Get CloudFront domain

```bash
terraform output -raw cloudfront_domain_name
# or
make outputs
```

Notes & considerations
- This setup uses the S3 website endpoint as CloudFront origin, and the S3 bucket is set to public-read for simplicity.
- For production, consider using Origin Access Control (OAC) and restricting bucket access to CloudFront only.
- If you want to use a custom domain and TLS, add an ACM certificate and configure the CloudFront distribution's viewer_certificate.

Security
- Currently the bucket is public-read. If you require restricted access, we'll switch to OAC and update the bucket policy accordingly.

Troubleshooting
- If `make s3-sync` fails, ensure `terraform apply` completed and outputs exist.
- If CloudFront returns old content, run `make cf-invalidate`.

