variable "name" {
  description = "Prefix for EFS resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EFS is deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for mount targets."
  type        = list(string)
}

variable "client_security_group_ids" {
  description = "Security groups that can mount the file system."
  type        = list(string)
  default     = []
}

variable "posix_uid" {
  description = "POSIX UID for the access point."
  type        = number
  default     = 1000
}

variable "posix_gid" {
  description = "POSIX GID for the access point."
  type        = number
  default     = 1000
}

variable "access_point_path" {
  description = "Root path exposed by the access point."
  type        = string
  default     = "/mnt/data"
}

variable "performance_mode" {
  description = "EFS performance mode."
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "EFS throughput mode."
  type        = string
  default     = "elastic"
}

variable "transition_to_ia" {
  description = "Lifecycle policy for infrequent access transitions."
  type        = string
  default     = "AFTER_7_DAYS"
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
