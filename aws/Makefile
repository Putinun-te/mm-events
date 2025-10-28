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
	docker build -f Dockerfile.k8s -t concert-backend:latest . && \
	docker tag concert-backend:latest $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-backend:latest && \
	docker push $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-backend:latest

aws-build-frontend:
	@echo "Building and pushing frontend image..."
	cd ../main_frontend/concert1 && \
	docker build -f Dockerfile.k8s -t concert-frontend:latest . && \
	docker tag concert-frontend:latest $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-frontend:latest && \
	docker push $$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$(AWS_REGION).amazonaws.com/concert/concert-frontend:latest

aws-build-all: aws-login aws-build-backend aws-build-frontend

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
