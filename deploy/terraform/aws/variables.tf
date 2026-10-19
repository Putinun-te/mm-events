variable "project" {
  description = "Name prefix for every resource."
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

variable "image_tag" {
  description = "Tag of the backend image in ECR to run."
  type        = string
  default     = "latest"
}

variable "spring_profile" {
  description = "Spring profile. The 'railway' profile reads everything (port, database, JWT secret, CORS) from environment variables, so it works on any container platform."
  type        = string
  default     = "railway"
}

variable "backend_cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU)."
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Fargate task memory in MiB. The image starts the JVM with -Xmx512m."
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Number of backend tasks."
  type        = number
  default     = 1
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
  description = "How long CloudWatch keeps the backend logs."
  type        = number
  default     = 14
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. PriceClass_200 includes Asia."
  type        = string
  default     = "PriceClass_200"
}
