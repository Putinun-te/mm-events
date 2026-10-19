variable "project_id" {
  description = "ID of an existing GCP project with billing enabled."
  type        = string
}

variable "name" {
  description = "Name prefix for every resource."
  type        = string
  default     = "mm-events"
}

variable "region" {
  description = "Region for Cloud Run, Cloud SQL and Artifact Registry."
  type        = string
  default     = "asia-southeast1"
}

variable "subnet_cidr" {
  description = "Subnet that Cloud Run uses for Direct VPC egress to Cloud SQL."
  type        = string
  default     = "10.50.0.0/24"
}

variable "domain" {
  description = "Optional domain for HTTPS (Google-managed certificate). Point its A record at the 'load_balancer_ip' output. Empty = HTTP only on the load balancer IP."
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "Tag of the backend image in Artifact Registry to run."
  type        = string
  default     = "latest"
}

variable "spring_profile" {
  description = "Spring profile. The 'railway' profile reads everything (port, database, JWT secret, CORS) from environment variables, so it works on any container platform."
  type        = string
  default     = "railway"
}

variable "backend_cpu" {
  description = "vCPUs per Cloud Run instance."
  type        = string
  default     = "1"
}

variable "backend_memory" {
  description = "Memory per Cloud Run instance. The image starts the JVM with -Xmx512m."
  type        = string
  default     = "1Gi"
}

variable "min_instances" {
  description = "Minimum Cloud Run instances. 0 scales to zero (cheapest, but the first request after idle waits for Spring Boot to start)."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum Cloud Run instances."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "MySQL database name."
  type        = string
  default     = "concert_db"
}

variable "db_username" {
  description = "MySQL user for the application."
  type        = string
  default     = "concert"
}

variable "db_tier" {
  description = "Cloud SQL machine type. db-f1-micro is the smallest shared-core tier."
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size_gb" {
  description = "Cloud SQL disk size in GB."
  type        = number
  default     = 10
}

variable "secret_version" {
  description = "Bump to generate and store a new database password and JWT secret."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Protect Cloud SQL and Cloud Run from deletion. Off by default so that 'terraform destroy' works for a demo; turn it on for real data."
  type        = bool
  default     = false
}
