variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "enable_versioning" {
  description = "Whether to enable bucket versioning."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket."
  type = list(object({
    id                          = string
    status                      = string
    transition_days             = number
    storage_class               = string
    noncurrent_transition_days  = number
    noncurrent_storage_class    = string
  }))
  default = []
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
