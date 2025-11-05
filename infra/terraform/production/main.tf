terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "concert-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

module "serverless" {
  source = "../serverless"

  project_name               = var.project_name
  environment                = var.environment
  region                     = var.region
  s3_bucket_name             = var.s3_bucket_name
  lambda_image_uri           = var.lambda_image_uri
  cognito_callback_urls      = var.cognito_callback_urls
  cognito_logout_urls        = var.cognito_logout_urls
  enable_elasticache         = var.enable_elasticache
  enable_cloudwatch_alarms   = var.enable_cloudwatch_alarms
  enable_cloudwatch_dashboard = var.enable_cloudwatch_dashboard
  cloudwatch_alarm_actions   = var.cloudwatch_alarm_actions
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_multi_az                = var.db_multi_az
  lambda_memory_size         = var.lambda_memory_size
  lambda_timeout             = var.lambda_timeout
  redis_max_data_storage_gb  = var.redis_max_data_storage_gb
  redis_max_ecpu_per_second  = var.redis_max_ecpu_per_second
}
