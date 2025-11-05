variable "project_name" {
  description = "Project identifier used in resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-east-1"
}

variable "additional_tags" {
  description = "Extra tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Optional explicit AZ list."
  type        = list(string)
  default     = []
}

variable "subnet_count" {
  description = "Number of AZs/subnets to create when AZ list is empty."
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "Optional list of public subnet CIDRs."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Optional list of private subnet CIDRs."
  type        = list(string)
  default     = []
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name for uploads."
  type        = string
}

variable "s3_enable_versioning" {
  description = "Enable versioning on the S3 bucket."
  type        = bool
  default     = false
}

variable "s3_lifecycle_rules" {
  description = "Lifecycle rules for S3 storage optimization."
  type = list(object({
    id                         = string
    status                     = string
    transition_days            = number
    storage_class              = string
    noncurrent_transition_days = number
    noncurrent_storage_class   = string
  }))
  default = [
    {
      id                         = "transition-to-intelligent-tiering"
      status                     = "Enabled"
      transition_days            = 30
      storage_class              = "INTELLIGENT_TIERING"
      noncurrent_transition_days = 30
      noncurrent_storage_class   = "INTELLIGENT_TIERING"
    }
  ]
}

variable "cognito_callback_urls" {
  description = "Allowed app callback URLs."
  type        = list(string)
  default     = []
}

variable "cognito_logout_urls" {
  description = "Allowed logout URLs."
  type        = list(string)
  default     = []
}

variable "cognito_domain_prefix" {
  description = "Cognito hosted domain prefix. Must be globally unique or leave empty."
  type        = string
  default     = ""
}

variable "db_engine" {
  description = "Database engine identifier."
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version."
  type        = string
  default     = "8.0.43"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Max autoscaled storage in GB."
  type        = number
  default     = 100
}

variable "db_storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "concert"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "concert"
}

variable "db_port" {
  description = "Database port."
  type        = number
  default     = 3306
}

variable "db_multi_az" {
  description = "Enable Multi-AZ."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = true
}

variable "db_backup_retention_days" {
  description = "Days to retain automatic backups."
  type        = number
  default     = 7
}

variable "db_performance_insights" {
  description = "Enable Performance Insights."
  type        = bool
  default     = false
}

variable "db_monitoring_interval" {
  description = "Enhanced monitoring interval."
  type        = number
  default     = 0
}

variable "efs_access_point_path" {
  description = "Root directory path on EFS."
  type        = string
  default     = "/data"
}

variable "efs_performance_mode" {
  description = "EFS performance mode."
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode."
  type        = string
  default     = "elastic"
}

variable "efs_transition_to_ia" {
  description = "Lifecycle policy for EFS infrequent access."
  type        = string
  default     = "AFTER_7_DAYS"
}

variable "lambda_package_type" {
  description = "Lambda package type."
  type        = string
  default     = "Image"
}

variable "lambda_image_uri" {
  description = "Lambda container image URI."
  type        = string
  default     = ""
}

variable "lambda_deployment_package_path" {
  description = "Path to zip artifact if using Zip package."
  type        = string
  default     = null
}

variable "lambda_runtime" {
  description = "Runtime for Zip package deployments."
  type        = string
  default     = null
}

variable "lambda_handler" {
  description = "Handler for Zip package deployments."
  type        = string
  default     = null
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 120
}

variable "lambda_memory_size" {
  description = "Lambda memory size."
  type        = number
  default     = 1024
}

variable "lambda_architecture" {
  description = "Lambda CPU architecture."
  type        = string
  default     = "x86_64"
}

variable "lambda_efs_mount_path" {
  description = "Mount path inside Lambda for EFS."
  type        = string
  default     = "/mnt/data"
}

variable "lambda_environment_overrides" {
  description = "Custom environment variables merged into the function."
  type        = map(string)
  default     = {}
}

variable "lambda_additional_policy_arns" {
  description = "Managed policy ARNs for Lambda IAM role attachments."
  type        = list(string)
  default     = []
}

variable "lambda_enable_jwt_authorizer" {
  description = "Enable JWT authorizer on the API Gateway routes."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "Log retention for CloudWatch log groups."
  type        = number
  default     = 14
}

variable "cloudwatch_kms_key_id" {
  description = "Optional KMS key ARN for encrypting CloudWatch logs."
  type        = string
  default     = ""
}

variable "api_stage_name" {
  description = "Name of the deployed API Gateway stage."
  type        = string
  default     = "prod"
}

variable "api_throttling_burst" {
  description = "API Gateway throttling burst limit."
  type        = number
  default     = 100
}

variable "api_throttling_rate" {
  description = "API Gateway throttling steady rate."
  type        = number
  default     = 50
}

variable "enable_elasticache" {
  description = "Provision an ElastiCache serverless Redis cache."
  type        = bool
  default     = false
}

variable "redis_max_data_storage_gb" {
  description = "Maximum data storage for serverless cache (GB)."
  type        = number
  default     = 20
}

variable "redis_max_ecpu_per_second" {
  description = "Maximum ECPU per second for serverless cache."
  type        = number
  default     = 100
}

variable "redis_daily_snapshot_time" {
  description = "Daily snapshot window (UTC HH:MM)."
  type        = string
  default     = "04:00"
}

variable "redis_kms_key_id" {
  description = "Optional customer-managed KMS key for Redis encryption."
  type        = string
  default     = ""
}

variable "enable_cloudwatch_alarms" {
  description = "Create CloudWatch metric alarms for Lambda, API Gateway, and RDS."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_dashboard" {
  description = "Create an overview CloudWatch dashboard."
  type        = bool
  default     = true
}

variable "cloudwatch_alarm_actions" {
  description = "Alarm action ARNs (e.g., SNS topics)."
  type        = list(string)
  default     = []
}

variable "cloudwatch_ok_actions" {
  description = "OK action ARNs."
  type        = list(string)
  default     = []
}

variable "lambda_error_threshold" {
  description = "Lambda error threshold before alarm."
  type        = number
  default     = 1
}

variable "lambda_error_period" {
  description = "Lambda error metric period (seconds)."
  type        = number
  default     = 300
}

variable "lambda_error_evaluation_periods" {
  description = "Evaluation periods for Lambda error alarm."
  type        = number
  default     = 1
}

variable "lambda_error_datapoints_to_alarm" {
  description = "Datapoints to alarm for Lambda error alarm."
  type        = number
  default     = 1
}

variable "api_5xx_threshold" {
  description = "API Gateway 5XX count threshold."
  type        = number
  default     = 1
}

variable "api_5xx_period" {
  description = "API Gateway 5XX metric period (seconds)."
  type        = number
  default     = 300
}

variable "api_5xx_evaluation_periods" {
  description = "Evaluation periods for API 5XX alarm."
  type        = number
  default     = 1
}

variable "api_5xx_datapoints_to_alarm" {
  description = "Datapoints to alarm for API 5XX alarm."
  type        = number
  default     = 1
}

variable "db_cpu_threshold" {
  description = "RDS CPU utilization threshold (percent)."
  type        = number
  default     = 70
}

variable "db_cpu_period" {
  description = "RDS CPU metric period (seconds)."
  type        = number
  default     = 300
}

variable "db_cpu_evaluation_periods" {
  description = "Evaluation periods for RDS CPU alarm."
  type        = number
  default     = 3
}

variable "db_cpu_datapoints_to_alarm" {
  description = "Datapoints to alarm for RDS CPU alarm."
  type        = number
  default     = 2
}
