# Free Tier Configuration Variables

variable "enable_alb" {
  description = "Enable Application Load Balancer (costs $15-20/month, not free-tier eligible)"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (costs $32/month + data transfer)"
  type        = bool
  default     = false
}

variable "enable_multi_az_rds" {
  description = "Enable Multi-AZ RDS (doubles cost, not needed for dev)"
  type        = bool
  default     = false
}

variable "enable_rds_iops" {
  description = "Enable IOPS for RDS (costs $0.02/GB/month, not compatible with free tier)"
  type        = bool
  default     = false
}

variable "enable_ecs_fargate" {
  description = "Enable ECS on Fargate (costs per vCPU/hour). False = EC2 only (free tier)"
  type        = bool
  default     = false
}

variable "free_tier_mode" {
  description = "Enable free tier optimization (removes expensive resources)"
  type        = bool
  default     = true
}

variable "ec2_root_volume_size_free_tier" {
  description = "EC2 root volume size in GB for free tier (keep small)"
  type        = number
  default     = 20
}

variable "cloudwatch_log_retention_free_tier" {
  description = "CloudWatch log retention days (free tier: 5 GB ingestion included)"
  type        = number
  default     = 3
}
