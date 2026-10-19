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
  description = "Azure region."
  type        = string
  default     = "southeastasia"
}

variable "vnet_cidr" {
  description = "Address space of the VNet: a /22 for AKS, a /24 for MySQL and a /24 for Application Gateway for Containers."
  type        = string
  default     = "10.60.0.0/16"
}

variable "service_cidr" {
  description = "Kubernetes Service range; must not overlap the VNet."
  type        = string
  default     = "10.61.0.0/16"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version, e.g. \"1.34\". null = the current AKS default ('az aks get-versions')."
  type        = string
  default     = null
}

variable "api_server_authorized_ip_ranges" {
  description = "Networks allowed to reach the Kubernetes API. Empty = no restriction. Set this to your own IP."
  type        = list(string)
  default     = []
}

variable "node_vm_size" {
  description = "VM size of the node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Initial number of nodes."
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum nodes (cluster autoscaler)."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes (cluster autoscaler)."
  type        = number
  default     = 3
}

variable "k8s_namespace" {
  description = "Namespace the Helm chart is installed into."
  type        = string
  default     = "mm-events"
}

variable "k8s_service_account" {
  description = "Service account of the backend (chart value backend.serviceAccount.name). Its federated managed identity may read the two Key Vault secrets."
  type        = string
  default     = "mm-events-backend"
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
  description = "Log Analytics retention for the cluster and container logs."
  type        = number
  default     = 30
}
