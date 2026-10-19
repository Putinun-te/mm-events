variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "name" {
  description = "Name prefix for every resource. Globally unique names (ACR, Key Vault, MySQL) get a random suffix."
  type        = string
  default     = "mm-events"
}

variable "location" {
  description = "Azure region for everything except the Static Web App."
  type        = string
  default     = "southeastasia"
}

variable "static_web_app_location" {
  description = "Region of the Static Web App's management resource (only a few regions are offered; the site itself is served globally)."
  type        = string
  default     = "eastasia"
}

variable "vnet_cidr" {
  description = "Address space of the VNet. A /23 goes to Container Apps, a /24 to MySQL."
  type        = string
  default     = "10.60.0.0/16"
}

variable "image_tag" {
  description = "Tag of the backend image in ACR to run."
  type        = string
  default     = "latest"
}

variable "spring_profile" {
  description = "Spring profile. The 'railway' profile reads everything (port, database, JWT secret, CORS) from environment variables, so it works on any container platform."
  type        = string
  default     = "railway"
}

variable "backend_cpu" {
  description = "vCPUs per replica (Consumption profile: 0.25 steps, memory = 2 GiB per vCPU)."
  type        = number
  default     = 0.5
}

variable "backend_memory" {
  description = "Memory per replica. Must match backend_cpu (0.5 vCPU -> 1Gi). The image starts the JVM with -Xmx512m."
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replicas. 0 scales to zero (cheapest, but the first request after idle waits for Spring Boot to start)."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replicas."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "MySQL database name."
  type        = string
  default     = "concert_db"
}

variable "db_username" {
  description = "MySQL administrator login, used by the application."
  type        = string
  default     = "concert"
}

variable "db_sku" {
  description = "MySQL Flexible Server SKU. B_Standard_B1ms is the smallest burstable size."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_gb" {
  description = "MySQL storage in GB."
  type        = number
  default     = 20
}

variable "secret_version" {
  description = "Bump to generate and store a new database password and JWT secret."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Log Analytics retention for the backend logs."
  type        = number
  default     = 30
}
