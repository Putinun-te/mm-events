# Terraform Variables
# Configuration for Concert AWS infrastructure

# ============================================================================
# GENERAL VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name (dev, test, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, test, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "concert"
}

# ============================================================================
# VPC VARIABLES
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.11.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.12.0/24"
}

# ============================================================================
# RDS VARIABLES
# ============================================================================

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
  default     = "concert_db"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

# ============================================================================
# ELASTICACHE VARIABLES
# ============================================================================

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  type        = string
}

# ============================================================================
# NETWORK VARIABLES
# ============================================================================

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "RDS security group ID"
  type        = string
}

variable "lambda_security_group_id" {
  description = "Lambda security group ID"
  type        = string
}

# ============================================================================
# MESSAGING VARIABLES
# ============================================================================

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for ElastiCache"
  type        = string
  default     = "/aws/elasticache/concert"
}

# ============================================================================
# TAGS
# ============================================================================

variable "frontend_domain" {
  description = "Frontend domain for CORS configuration"
  type        = string
  default     = "localhost:3000"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "concert"
    ManagedBy   = "terraform"
    Environment = "development"
  }
}

# ============================================================================
# OUTPUT VARIABLES
# ============================================================================

output "terraform_version" {
  value = "~> 1.0"
}

output "aws_provider_version" {
  value = "~> 5.0"
}
