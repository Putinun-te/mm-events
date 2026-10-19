variable "project" {
  description = "Name prefix for every resource; also the EKS cluster name."
  type        = string
  default     = "mm-events"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC. Two public and two private /20 subnets are carved out of it."
  type        = string
  default     = "10.40.0.0/16"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version, e.g. \"1.34\". null = the current EKS default ('aws eks describe-cluster-versions')."
  type        = string
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Networks allowed to reach the public Kubernetes API endpoint. Narrow this to your own IP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types of the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Initial number of nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Root volume of each node in GiB."
  type        = number
  default     = 30
}

variable "k8s_namespace" {
  description = "Namespace the Helm chart is installed into."
  type        = string
  default     = "mm-events"
}

variable "k8s_service_account" {
  description = "Service account of the backend (chart value backend.serviceAccount.name). Its IRSA role may read the two secrets."
  type        = string
  default     = "mm-events-backend"
}

variable "db_name" {
  description = "MySQL database name."
  type        = string
  default     = "concert_db"
}

variable "db_username" {
  description = "MySQL master user name. Its password is generated and kept in Secrets Manager by RDS."
  type        = string
  default     = "concert"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}

variable "secret_version" {
  description = "Bump to generate and store a new JWT secret (the DB password is rotated by RDS)."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Protect the database from deletion. Off by default so that 'terraform destroy' works for a demo; turn it on for real data."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "How long CloudWatch keeps the EKS control-plane logs."
  type        = number
  default     = 14
}
