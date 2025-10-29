.PHONY: help init plan apply destroy validate fmt console logs clean

AWS_REGION ?= us-east-1
ENVIRONMENT ?= dev

help:
	@echo "Concert AWS Deployment Makefile"
	@echo "================================"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help           - Show this help message"
	@echo "  init           - Initialize Terraform"
	@echo "  validate       - Validate Terraform configuration"
	@echo "  fmt            - Format Terraform files"
	@echo "  plan           - Plan the deployment"
	@echo "  apply          - Apply the deployment"
	@echo "  destroy        - Destroy all resources"
	@echo ""
	@echo "FREE TIER TARGETS (Recommended for new AWS accounts):"
	@echo "  free-tier-plan - Plan free-tier deployment (S3+CloudFront+RDS+EC2, no ALB)"
	@echo "  free-tier-apply - Apply free-tier deployment"
	@echo "  free-tier-destroy - Destroy free-tier resources"
	@echo ""
	@echo "Other targets:"
	@echo "  outputs        - Show Terraform outputs"
	@echo "  logs           - Follow CloudWatch logs"
	@echo "  console        - Open Terraform console"
	@echo "  clean          - Clean Terraform cache"
	@echo ""
	@echo "Environment variables:"
	@echo "  AWS_REGION     - AWS region (default: us-east-1)"
	@echo "  ENVIRONMENT    - Environment name (default: dev)"
	@echo ""

init:
	@echo "Initializing Terraform..."
	terraform init

validate:
	@echo "Validating Terraform configuration..."
	terraform validate

fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

plan:
	@echo "Planning Terraform deployment..."
	terraform plan -out=tfplan

apply:
	@echo "Applying Terraform configuration..."
	terraform apply tfplan
	@echo ""
	@echo "Deployment complete! Access your application at:"
	@echo "  $$(terraform output -raw application_url)"
	@echo ""
	@echo "API endpoint:"
	@echo "  $$(terraform output -raw api_url)"

destroy:
	@echo "WARNING: This will destroy all AWS resources including the RDS database!"
	@read -p "Are you sure? (yes/no): " response; \
	if [ "$$response" = "yes" ]; then \
		terraform destroy; \
	else \
		echo "Destroy cancelled."; \
	fi

outputs:
	@echo "Terraform Outputs:"
	@echo "==================="
	terraform output

logs:
	@echo "Following CloudWatch logs..."
	aws logs tail /ecs/concert --follow --region $(AWS_REGION)

console:
	@echo "Opening Terraform console..."
	terraform console

clean:
	@echo "Cleaning Terraform cache..."
	rm -rf .terraform/ .terraform.lock.hcl tfplan

# Development targets
dev-init:
	cp terraform.tfvars.example terraform.tfvars
	@echo "Created terraform.tfvars from example"
	@echo "Please edit terraform.tfvars with your values"

dev-plan:
	terraform plan -out=tfplan

dev-apply:
	terraform apply tfplan

dev-destroy:
	terraform destroy

# AWS-specific targets
aws-login:
	@echo "Logging into AWS ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com

aws-build-backend:
	@echo "Building and pushing backend image..."
	cd ../main_backend && \
	docker build -f Dockerfile -t concert-backend:latest . && \
	docker tag concert-backend:latest $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-backend:latest && \
	docker push $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-backend:latest

aws-build-frontend:
	@echo "Building and pushing frontend image..."
	cd ../main_frontend/concert1 && \
	docker build -f Dockerfile -t concert-frontend:latest . && \
	docker tag concert-frontend:latest $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-frontend:latest && \
	docker push $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-frontend:latest

aws-build-all: aws-login aws-build-backend aws-build-frontend

# Sync built frontend files to S3 (expects ./main_frontend/concert1/.output or build dir)
.PHONY: s3-sync cf-invalidate

s3-sync:
	@echo "Syncing frontend build to S3..."
	@FRONTEND_DIR=../main_frontend/concert1/dist || FRONTEND_DIR=../main_frontend/concert1/.output
	@BUCKET=$$(terraform output -raw frontend_s3_bucket_name 2>/dev/null || echo ""); \
	if [ -z "$$BUCKET" ]; then \
		echo "S3 bucket not found in terraform outputs. Run 'make apply' or 'terraform apply' first."; exit 1; \
	fi; \
	# prefer dist then .output
	if [ -d ../main_frontend/concert1/dist ]; then \
		aws s3 sync ../main_frontend/concert1/dist s3://$$BUCKET --delete --acl public-read --region $(AWS_REGION); \
	else \
		aws s3 sync ../main_frontend/concert1/.output s3://$$BUCKET --delete --acl public-read --region $(AWS_REGION); \
	fi

cf-invalidate:
	@echo "Invalidating CloudFront distribution cache..."
	@DIST_ID=$$(terraform output -raw frontend_cdn_id 2>/dev/null || terraform output -raw frontend_cdn_id 2>/dev/null || echo ""); \
	if [ -z "$$DIST_ID" ]; then \
		echo "CloudFront distribution id not found in terraform outputs. Run 'make apply' or 'terraform apply' first."; exit 1; \
	fi; \
	aws cloudfront create-invalidation --distribution-id $$DIST_ID --paths "/*" --region $(AWS_REGION) >/dev/null; \
	echo "Invalidation requested for $$DIST_ID"

# FREE TIER TARGETS
.PHONY: free-tier-plan free-tier-apply free-tier-destroy free-tier-status

free-tier-plan:
	@echo "=========================================="
	@echo "Planning FREE TIER deployment"
	@echo "=========================================="
	@echo ""
	@echo "✓ S3 + CloudFront (frontend)"
	@echo "✓ RDS (db.t3.micro, 20 GB)"
	@echo "✓ EC2 (t3.micro instances)"
	@echo "✗ ALB (not free-tier eligible)"
	@echo "✗ NAT Gateway (extra costs)"
	@echo "✗ ECS Fargate (costs per CPU/hour)"
	@echo ""
	@echo "Cost: $0 for 12 months (first-time AWS account)"
	@echo ""
	terraform plan \
		-var="enable_alb=false" \
		-var="enable_nat_gateway=false" \
		-var="enable_ecs_fargate=false" \
		-var="free_tier_mode=true" \
		-var="ec2_instance_type=t3.micro" \
		-var="db_allocated_storage=20" \
		-var="db_instance_class=db.t3.micro" \
		-out=tfplan-free-tier

free-tier-apply:
	@echo "=========================================="
	@echo "Applying FREE TIER deployment"
	@echo "=========================================="
	@if [ -f tfplan-free-tier ]; then \
		terraform apply tfplan-free-tier; \
		echo ""; \
		echo "✅ Deployment complete!"; \
		echo ""; \
		echo "Frontend (CloudFront):"; \
		echo "  $$(terraform output -raw cloudfront_domain_name 2>/dev/null || echo 'N/A')"; \
		echo ""; \
		echo "Backend (EC2):"; \
		echo "  $$(terraform output -raw backend_ec2_eip 2>/dev/null || echo 'N/A'):8080"; \
		echo ""; \
		echo "Database (RDS):"; \
		echo "  $$(terraform output -raw rds_endpoint 2>/dev/null || echo 'N/A')"; \
		echo ""; \
		echo "Next steps:"; \
		echo "  1. Build frontend: cd ../main_frontend/concert1 && npm run build"; \
		echo "  2. Sync to S3: make s3-sync"; \
		echo "  3. Invalidate CloudFront: make cf-invalidate"; \
		echo "  4. Visit CloudFront domain in browser"; \
	else \
		echo "Plan file not found. Run 'make free-tier-plan' first."; \
		exit 1; \
	fi

free-tier-destroy:
	@echo "WARNING: This will destroy all free-tier AWS resources!"
	@read -p "Are you sure? (yes/no): " response; \
	if [ "$$response" = "yes" ]; then \
		terraform destroy \
			-var="enable_alb=false" \
			-var="enable_nat_gateway=false" \
			-var="enable_ecs_fargate=false" \
			-var="free_tier_mode=true"; \
	else \
		echo "Destroy cancelled."; \
	fi

free-tier-status:
	@echo "=========================================="
	@echo "FREE TIER Deployment Status"
	@echo "=========================================="
	@echo ""
	@echo "S3 Bucket:"
	@terraform output frontend_s3_bucket_name 2>/dev/null || echo "Not deployed"
	@echo ""
	@echo "CloudFront Domain:"
	@terraform output cloudfront_domain_name 2>/dev/null || echo "Not deployed"
	@echo ""
	@echo "Backend EC2:"
	@terraform output backend_ec2_eip 2>/dev/null || echo "Not deployed"
	@echo ""
	@echo "RDS Endpoint:"
	@terraform output rds_endpoint 2>/dev/null || echo "Not deployed"

deploy-services:
	@echo "Deploying services to ECS..."
	@echo "Forcing backend service to update..."
	aws ecs update-service \
		--cluster concert-cluster \
		--service concert-backend-service \
		--force-new-deployment \
		--region $(AWS_REGION) \
		--output json | jq '.service | {serviceName, status, runningCount, desiredCount}'
	@echo "Forcing frontend service to update..."
	aws ecs update-service \
		--cluster concert-cluster \
		--service concert-frontend-service \
		--force-new-deployment \
		--region $(AWS_REGION) \
		--output json | jq '.service | {serviceName, status, runningCount, desiredCount}'
	@echo ""
	@echo "Services are updating. Run 'make status' to check progress."

# Monitoring targets
monitor-services:
	@echo "Checking ECS services status..."
	aws ecs describe-services \
		--cluster concert-cluster \
		--services concert-backend-service concert-frontend-service \
		--region $(AWS_REGION) \
		--query 'services[*].[serviceName,status,runningCount,desiredCount]' \
		--output table

monitor-tasks:
	@echo "Listing ECS tasks..."
	aws ecs list-tasks \
		--cluster concert-cluster \
		--region $(AWS_REGION) \
		--output table

monitor-rds:
	@echo "Checking RDS database status..."
	aws rds describe-db-instances \
		--db-instance-identifier concert-mysql \
		--region $(AWS_REGION) \
		--query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,DBInstanceClass]' \
		--output table

monitor-alb-health:
	@echo "Checking ALB target health..."
	@ALB_ARN=$$(terraform output -raw alb_dns_name 2>/dev/null || echo ""); \
	if [ -n "$$ALB_ARN" ]; then \
		TG_ARNS=$$(aws elbv2 describe-load-balancers --region $(AWS_REGION) | jq -r '.LoadBalancers[0].LoadBalancerArn'); \
		aws elbv2 describe-target-groups \
			--load-balancer-arn $$TG_ARNS \
			--region $(AWS_REGION) \
			--query 'TargetGroups[*].[TargetGroupArn,TargetType]' \
			--output table; \
	else \
		echo "ALB not deployed yet"; \
	fi

# Helper targets
status:
	@echo "Concert AWS Deployment Status"
	@echo "=============================="
	@echo ""
	@make monitor-services
	@echo ""
	@make monitor-rds

version:
	@terraform version

# EC2 Targets
ec2-plan:
	@echo "Planning EC2 deployment..."
	terraform plan -target=aws_instance.backend -target=aws_instance.frontend -target=aws_security_group.ec2 -out=ec2.plan

ec2-apply:
	@echo "Applying EC2 deployment..."
	@if [ -f ec2.plan ]; then \
		terraform apply ec2.plan; \
	else \
		terraform apply -target=aws_instance.backend -target=aws_instance.frontend -target=aws_security_group.ec2 -auto-approve; \
	fi
	@echo ""
	@echo "✓ EC2 instances deployed!"
	@echo ""
	@echo "Access your instances:"
	@echo "Backend SSH:  $$(terraform output -raw backend_ec2_ssh_command 2>/dev/null || echo 'N/A')"
	@echo "Frontend SSH: $$(terraform output -raw frontend_ec2_ssh_command 2>/dev/null || echo 'N/A')"
	@echo ""
	@echo "Wait 2-3 minutes for instances to fully initialize..."

ec2-destroy:
	@echo "Destroying EC2 instances..."
	terraform destroy -target=aws_instance.backend -target=aws_instance.frontend -target=aws_security_group.ec2 -auto-approve

ec2-status:
	@echo "EC2 Instances Status"
	@echo "===================="
	@echo ""
	@aws ec2 describe-instances \
		--filters "Name=tag:Project,Values=Concert" \
		--region $(AWS_REGION) \
		--query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PublicIpAddress,InstanceType]' \
		--output table

ec2-connect-backend:
	@echo "Connecting to backend EC2 instance..."
	@BACKEND_EIP=$$(terraform output -raw backend_ec2_eip 2>/dev/null || terraform output -raw backend_ec2_public_ip 2>/dev/null); \
	if [ -z "$$BACKEND_EIP" ]; then \
		echo "Backend instance not found or not deployed"; \
	else \
		ssh -i concert-key.pem -o StrictHostKeyChecking=no ubuntu@$$BACKEND_EIP; \
	fi

ec2-connect-frontend:
	@echo "Connecting to frontend EC2 instance..."
	@FRONTEND_EIP=$$(terraform output -raw frontend_ec2_eip 2>/dev/null || terraform output -raw frontend_ec2_public_ip 2>/dev/null); \
	if [ -z "$$FRONTEND_EIP" ]; then \
		echo "Frontend instance not found or not deployed"; \
	else \
		ssh -i concert-key.pem -o StrictHostKeyChecking=no ubuntu@$$FRONTEND_EIP; \
	fi

ec2-logs-backend:
	@echo "Tailing backend EC2 logs..."
	@BACKEND_ID=$$(terraform output -raw backend_ec2_instance_id 2>/dev/null); \
	if [ -z "$$BACKEND_ID" ]; then \
		echo "Backend instance not found"; \
	else \
		aws logs tail /concert/ec2/docker --follow --log-stream-name-prefix $$BACKEND_ID; \
	fi

ec2-logs-frontend:
	@echo "Tailing frontend EC2 logs..."
	@FRONTEND_ID=$$(terraform output -raw frontend_ec2_instance_id 2>/dev/null); \
	if [ -z "$$FRONTEND_ID" ]; then \
		echo "Frontend instance not found"; \
	else \
		aws logs tail /concert/ec2/docker --follow --log-stream-name-prefix $$FRONTEND_ID; \
	fi

ec2-deploy-containers:
	@echo "Starting EC2 deployment helper..."
	@chmod +x ec2-deploy.sh
	@./ec2-deploy.sh

ec2-info:
	@echo "EC2 Deployment Information"
	@echo "=========================="
	@echo ""
	@echo "Backend Instance:"
	@terraform output backend_ec2_instance_id backend_ec2_public_ip backend_ec2_eip backend_ec2_ssh_command 2>/dev/null || echo "Not deployed"
	@echo ""
	@echo "Frontend Instance:"
	@terraform output frontend_ec2_instance_id frontend_ec2_public_ip frontend_ec2_eip frontend_ec2_ssh_command 2>/dev/null || echo "Not deployed"
