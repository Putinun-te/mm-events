variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "concert"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "rds_username" {
  description = "RDS username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "rds_password" {
  description = "RDS master password (set in terraform.tfvars or TF_VAR_rds_password; no default)"
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "backend_service_url" {
  description = "Base URL of the backend service that API Gateway should proxy to (include protocol, no trailing slash)"
  type        = string
  default     = "http://localhost:8080"
}

variable "api_allowed_origins" {
  description = "List of origins allowed to call the API Gateway (CORS)"
  type        = list(string)
  default     = [
    "http://localhost:3000",
    "https://localhost:3000"
  ]
}

variable "api_stage_name" {
  description = "Stage name for the HTTP API Gateway deployment"
  type        = string
  default     = "prod"
}
