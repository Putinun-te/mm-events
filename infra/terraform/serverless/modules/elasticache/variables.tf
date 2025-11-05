variable "name" {
  description = "Prefix for cache resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cache runs."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for cache networking (must be in at least two AZs)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups permitted to connect to the cache."
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "Extra security groups added to the cache ENIs."
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Port for Redis traffic."
  type        = number
  default     = 6379
}

variable "max_data_storage_gb" {
  description = "Maximum data storage limit (GB)."
  type        = number
  default     = 20
}

variable "max_ecpu_per_second" {
  description = "Maximum ECPU per second for serverless cache."
  type        = number
  default     = 100
}

variable "daily_snapshot_time" {
  description = "UTC snapshot window (HH:MM)."
  type        = string
  default     = "03:00"
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for encryption."
  type        = string
  default     = ""
}

variable "description" {
  description = "Cache description."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
