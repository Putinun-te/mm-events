variable "project_name" {
  description = "Project name"
  type        = string
  default     = "concert"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "container_image_uri" {
  description = "URI of the Docker image in ECR"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for file storage"
  type        = string
}

variable "efs_access_point_id" {
  description = "EFS access point ID"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito app client ID"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (leave empty to use HTTP only for testing)"
  type        = string
  default     = ""
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024  # 1 vCPU
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 2048  # 2 GB
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 4
}
