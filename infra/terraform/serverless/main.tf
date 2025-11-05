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
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  base_tags = merge({
    Project     = var.project_name,
    Environment = var.environment
  }, var.additional_tags)

  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, var.subnet_count)

  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for index in range(var.subnet_count) : cidrsubnet(var.vpc_cidr, 4, index)
  ]

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for index in range(var.subnet_count) : cidrsubnet(var.vpc_cidr, 4, index + 8)
  ]

}

module "network" {
  source = "./modules/network"

  name                 = "${var.project_name}-${var.environment}"
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  tags                 = local.base_tags
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-lambda"
  description = "Lambda egress"
  vpc_id      = module.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-lambda"
  })
}

resource "aws_security_group" "endpoints" {
  name        = "${var.project_name}-${var.environment}-endpoints"
  description = "Interface endpoint access"
  vpc_id      = module.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-endpoints"
  })
}

resource "aws_security_group_rule" "endpoints_ingress_lambda" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.endpoints.id
  source_security_group_id = aws_security_group.lambda.id
}

module "s3" {
  source = "./modules/s3_bucket"

  bucket_name         = var.s3_bucket_name
  enable_versioning   = var.s3_enable_versioning
  force_destroy       = true
  lifecycle_rules     = var.s3_lifecycle_rules
  tags                = local.base_tags
}

module "cognito" {
  source = "./modules/cognito"

  name           = "${var.project_name}-${var.environment}"
  callback_urls  = var.cognito_callback_urls
  logout_urls    = var.cognito_logout_urls
  domain_prefix  = var.cognito_domain_prefix
  tags           = local.base_tags
}

module "rds" {
  source = "./modules/rds"

  name                      = "${var.project_name}-${var.environment}"
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  allowed_security_group_ids = [aws_security_group.lambda.id]
  engine                    = var.db_engine
  engine_version            = var.db_engine_version
  instance_class            = var.db_instance_class
  allocated_storage         = var.db_allocated_storage
  max_allocated_storage     = var.db_max_allocated_storage
  storage_type              = var.db_storage_type
  database_name             = var.db_name
  username                  = var.db_username
  port                      = var.db_port
  multi_az                  = var.db_multi_az
  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.db_skip_final_snapshot
  backup_retention_days     = var.db_backup_retention_days
  performance_insights_enabled = var.db_performance_insights
  monitoring_interval          = var.db_monitoring_interval
  tags                      = local.base_tags
}

module "efs" {
  source = "./modules/efs"

  name                       = "${var.project_name}-${var.environment}"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  client_security_group_ids  = [aws_security_group.lambda.id]
  access_point_path          = var.efs_access_point_path
  performance_mode           = var.efs_performance_mode
  throughput_mode            = var.efs_throughput_mode
  transition_to_ia           = var.efs_transition_to_ia
  tags                       = local.base_tags
}

module "elasticache" {
  count = var.enable_elasticache ? 1 : 0

  source = "./modules/elasticache"

  name                       = "${var.project_name}-${var.environment}"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [aws_security_group.lambda.id]
  max_data_storage_gb        = var.redis_max_data_storage_gb
  max_ecpu_per_second        = var.redis_max_ecpu_per_second
  daily_snapshot_time        = var.redis_daily_snapshot_time
  kms_key_id                 = var.redis_kms_key_id
  description                = "Redis cache for ${var.project_name}-${var.environment}"
  tags                       = local.base_tags
}

module "lambda_api" {
  source = "./modules/lambda_api"

  name                    = "${var.project_name}-${var.environment}-api"
  package_type            = var.lambda_package_type
  image_uri               = var.lambda_image_uri
  deployment_package_path = var.lambda_deployment_package_path
  handler                 = var.lambda_handler
  runtime                 = var.lambda_runtime
  timeout                 = var.lambda_timeout
  memory_size             = var.lambda_memory_size
  architecture            = var.lambda_architecture
  subnet_ids              = module.network.private_subnet_ids
  security_group_ids      = [aws_security_group.lambda.id]
  efs_access_point_arn    = module.efs.access_point_arn
  efs_file_system_arn     = module.efs.file_system_arn
  efs_mount_path          = var.lambda_efs_mount_path
  secret_arn              = module.rds.secret_arn
  s3_bucket_arn           = module.s3.bucket_arn
  elasticache_cache_arn   = var.enable_elasticache ? module.elasticache[0].cache_arn : ""
  log_retention_in_days   = var.log_retention_in_days
  cloudwatch_kms_key_id   = var.cloudwatch_kms_key_id
  enable_jwt_authorizer   = var.lambda_enable_jwt_authorizer
  authorizer_jwt_issuer   = var.lambda_enable_jwt_authorizer ? "https://cognito-idp.${var.region}.amazonaws.com/${module.cognito.user_pool_id}" : ""
  authorizer_audience     = var.lambda_enable_jwt_authorizer ? [module.cognito.app_client_id] : []
  stage_name              = var.api_stage_name
  throttling_burst_limit  = var.api_throttling_burst
  throttling_rate_limit   = var.api_throttling_rate
  environment_variables = merge(
    {
      DB_SECRET_ARN        = module.rds.secret_arn,
      FILES_BUCKET         = module.s3.bucket_name,
      EFS_MOUNT            = var.lambda_efs_mount_path,
      RDS_ENDPOINT         = module.rds.endpoint,
      RDS_PORT             = tostring(var.db_port)
    },
    var.lambda_enable_jwt_authorizer ? {
      COGNITO_USER_POOL_ID = module.cognito.user_pool_id,
      COGNITO_CLIENT_ID    = module.cognito.app_client_id
    } : {},
    var.enable_elasticache ? {
      REDIS_ENDPOINT = module.elasticache[0].endpoint_address,
      REDIS_PORT     = tostring(module.elasticache[0].endpoint_port)
    } : {},
    var.lambda_environment_overrides
  )
  additional_policy_arns = var.lambda_additional_policy_arns
  tags                   = local.base_tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.network.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [module.network.private_subnet_route_table_id]

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "secrets" {
  vpc_id              = module.network.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.network.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-secrets-endpoint"
  })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.network.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.network.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-${var.environment}-logs-endpoint"
  })
}

module "cloudwatch" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  source = "./modules/cloudwatch"

  name                    = "${var.project_name}-${var.environment}"
  region                  = var.region
  lambda_function_name    = module.lambda_api.function_name
  api_id                  = module.lambda_api.api_id
  api_stage_name          = var.api_stage_name
  db_instance_identifier  = module.rds.db_instance_identifier
  alarm_actions           = var.cloudwatch_alarm_actions
  ok_actions              = var.cloudwatch_ok_actions
  lambda_error_threshold  = var.lambda_error_threshold
  lambda_error_period     = var.lambda_error_period
  lambda_error_evaluation_periods = var.lambda_error_evaluation_periods
  lambda_error_datapoints_to_alarm = var.lambda_error_datapoints_to_alarm
  api_5xx_threshold       = var.api_5xx_threshold
  api_5xx_period          = var.api_5xx_period
  api_5xx_evaluation_periods = var.api_5xx_evaluation_periods
  api_5xx_datapoints_to_alarm = var.api_5xx_datapoints_to_alarm
  db_cpu_threshold        = var.db_cpu_threshold
  db_cpu_period           = var.db_cpu_period
  db_cpu_evaluation_periods = var.db_cpu_evaluation_periods
  db_cpu_datapoints_to_alarm = var.db_cpu_datapoints_to_alarm
  enable_dashboard        = var.enable_cloudwatch_dashboard
}
