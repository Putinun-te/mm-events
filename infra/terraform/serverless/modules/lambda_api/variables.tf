variable "name" {
  description = "Lambda function name and resource prefix."
  type        = string
}

variable "package_type" {
  description = "Lambda deployment type (Image or Zip)."
  type        = string
  default     = "Image"
}

variable "image_uri" {
  description = "Container image URI in ECR (for package type Image)."
  type        = string
  default     = ""
}

variable "deployment_package_path" {
  description = "Path to zip package (for package type Zip)."
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda handler (Zip packages only)."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda runtime (Zip packages only)."
  type        = string
  default     = null
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory in MB."
  type        = number
  default     = 1024
}

variable "architecture" {
  description = "Lambda architecture."
  type        = string
  default     = "x86_64"
}

variable "environment_variables" {
  description = "Environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Subnets for Lambda VPC config."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups for Lambda VPC config."
  type        = list(string)
  default     = []
}

variable "efs_access_point_arn" {
  description = "EFS access point ARN mounted by the function."
  type        = string
  default     = ""
}

variable "efs_file_system_arn" {
  description = "EFS file system ARN for IAM permissions."
  type        = string
  default     = ""
}

variable "efs_mount_path" {
  description = "Local mount path for the EFS file system."
  type        = string
  default     = "/mnt/data"
}

variable "secret_arn" {
  description = "Secrets Manager ARN with database credentials."
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for object access."
  type        = string
  default     = ""
}

variable "elasticache_cache_arn" {
  description = "ElastiCache resource ARN for data-plane permissions."
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 14
}

variable "cloudwatch_kms_key_id" {
  description = "Optional KMS key for log encryption."
  type        = string
  default     = ""
}

variable "enable_jwt_authorizer" {
  description = "Enable Cognito JWT authorizer for API routes."
  type        = bool
  default     = true
}

variable "authorizer_jwt_issuer" {
  description = "JWT issuer URL (Cognito)."
  type        = string
  default     = ""
}

variable "authorizer_audience" {
  description = "JWT audience list (Cognito app client IDs)."
  type        = list(string)
  default     = []
}

variable "stage_name" {
  description = "API Gateway stage name."
  type        = string
  default     = "prod"
}

variable "throttling_burst_limit" {
  description = "API Gateway burst limit."
  type        = number
  default     = 50
}

variable "throttling_rate_limit" {
  description = "API Gateway steady-state rate limit."
  type        = number
  default     = 25
}

variable "additional_policy_arns" {
  description = "Additional IAM managed policies to attach to the Lambda role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
