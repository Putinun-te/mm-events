variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "environment" {
  description = "Environment (prod, staging, dev)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "lambda_image_uri" {
  description = "Lambda container image URI from ECR"
  type        = string
}

variable "cognito_callback_urls" {
  description = "Callback URLs for Cognito"
  type        = list(string)
  default     = []
}

variable "cognito_logout_urls" {
  description = "Logout URLs for Cognito"
  type        = list(string)
  default     = []
}

variable "enable_elasticache" {
  description = "Enable Redis cache"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_dashboard" {
  description = "Enable CloudWatch dashboard"
  type        = bool
  default     = true
}

variable "cloudwatch_alarm_actions" {
  description = "SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage (GB)"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "redis_max_data_storage_gb" {
  description = "Max Redis storage (GB)"
  type        = number
  default     = 20
}

variable "redis_max_ecpu_per_second" {
  description = "Max Redis ECPU/second (minimum 1000)"
  type        = number
  default     = 1000
}
