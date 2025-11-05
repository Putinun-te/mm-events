variable "name" {
  description = "Prefix for database resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups that can reach the database."
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Database engine."
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database engine version."
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "Instance class for RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage (GB)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (GB)."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3)."
  type        = string
  default     = "gp3"
}

variable "database_name" {
  description = "Database name."
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "appuser"
}

variable "port" {
  description = "Database port."
  type        = number
  default     = 3306
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention in days."
  type        = number
  default     = 7
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
