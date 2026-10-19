variable "project_id" {
  description = "ID of an existing GCP project with billing enabled."
  type        = string
}

variable "name" {
  description = "Name prefix for every resource; also the GKE cluster name."
  type        = string
  default     = "mm-events"
}

variable "region" {
  description = "Region for the subnet, Cloud SQL and Artifact Registry."
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "Zone of the zonal GKE cluster (the free tier credit covers one zonal or Autopilot cluster)."
  type        = string
  default     = "asia-southeast1-a"
}

variable "subnet_cidr" {
  description = "Primary range of the GKE subnet (nodes)."
  type        = string
  default     = "10.50.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for pod IPs."
  type        = string
  default     = "10.52.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range for Service IPs."
  type        = string
  default     = "10.53.0.0/20"
}

variable "master_cidr" {
  description = "/28 for the GKE control plane's private endpoint."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "Networks allowed to reach the Kubernetes API. Narrow this to your own IP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "release_channel" {
  description = "GKE release channel (picks the Kubernetes version and upgrades it)."
  type        = string
  default     = "REGULAR"
}

variable "node_machine_type" {
  description = "Machine type of the node pool."
  type        = string
  default     = "e2-medium"
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

variable "node_disk_size_gb" {
  description = "Boot disk of each node in GB."
  type        = number
  default     = 30
}

variable "k8s_namespace" {
  description = "Namespace the Helm chart is installed into."
  type        = string
  default     = "mm-events"
}

variable "k8s_service_account" {
  description = "Service account of the backend (chart value backend.serviceAccount.name). Workload Identity maps it to a Google service account that may read the two secrets."
  type        = string
  default     = "mm-events-backend"
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
  description = "Protect the GKE cluster and Cloud SQL from deletion. Off by default so that 'terraform destroy' works for a demo; turn it on for real data."
  type        = bool
  default     = false
}
