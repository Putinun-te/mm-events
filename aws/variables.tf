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
  description = "RDS password"
  type        = string
  default     = "REDACTED_DB_MASTER_PASSWORD"
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}
