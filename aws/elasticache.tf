# ElastiCache Redis Cluster Configuration
# In-memory data store for caching and sessions

# ============================================================================
# ELASTICACHE REPLICATION GROUP (Redis Cluster)
# ============================================================================

resource "aws_elasticache_replication_group" "concert" {
  replication_group_description = "Concert Redis cluster for caching and sessions"
  engine                        = "redis"
  engine_version                = "7.0"
  node_type                     = var.elasticache_node_type
  num_cache_clusters            = var.environment == "prod" ? 3 : 1
  parameter_group_name          = aws_elasticache_parameter_group.concert.name
  port                          = 6379
  
  # Networking
  subnet_group_name       = aws_elasticache_subnet_group.concert.name
  security_group_ids      = [var.elasticache_security_group_id]
  
  # High Availability
  automatic_failover_enabled = var.environment == "prod" ? true : false
  multi_az_enabled          = var.environment == "prod" ? true : false
  
  # Encryption
  transit_encryption_enabled = true
  auth_token                 = random_password.elasticache_auth_token.result
  at_rest_encryption_enabled = true
  
  # Snapshots
  snapshot_retention_limit = var.environment == "prod" ? 30 : 5
  snapshot_window          = "03:00-05:00"
  snapshot_name_prefix     = "concert-redis"
  
  # Maintenance
  maintenance_window = "sun:04:00-sun:05:00"
  notification_topic_arn = var.sns_topic_arn
  
  # Logging
  log_delivery_configuration {
    destination      = var.cloudwatch_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    enabled          = true
  }
  
  # Backup
  automatic_backup_enabled = true
  
  tags = {
    Name = "concert-redis-cluster-${var.environment}"
  }

  depends_on = [aws_elasticache_parameter_group.concert]
}

# ============================================================================
# ELASTICACHE PARAMETER GROUP
# ============================================================================

resource "aws_elasticache_parameter_group" "concert" {
  family      = "redis7"
  name_prefix = "concert-"
  description = "Concert Redis parameters"

  # Memory Management
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"  # Evict using LRU when max memory reached
  }

  # Connection Settings
  parameter {
    name  = "timeout"
    value = "300"  # Close connection after 300s idle
  }

  parameter {
    name  = "tcp-keepalive"
    value = "60"  # TCP keepalive
  }

  # Performance
  parameter {
    name  = "databases"
    value = "16"  # Number of databases
  }

  # Eviction
  parameter {
    name  = "maxmemory-samples"
    value = "3"  # Number of samples for LRU
  }

  tags = {
    Name = "concert-redis-params-${var.environment}"
  }
}

# ============================================================================
# ELASTICACHE SUBNET GROUP
# ============================================================================

resource "aws_elasticache_subnet_group" "concert" {
  name       = "concert-redis-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "concert-redis-subnet-group-${var.environment}"
  }
}

# ============================================================================
# ELASTICACHE AUTH TOKEN (Secrets Manager)
# ============================================================================

resource "random_password" "elasticache_auth_token" {
  length  = 32
  special = true
  # Exclude special characters that Redis auth doesn't support
  override_special = "!&#$^<>-"
}

resource "aws_secretsmanager_secret" "elasticache_auth" {
  name_prefix             = "concert-redis-auth-"
  recovery_window_in_days = 7

  tags = {
    Name = "concert-redis-auth-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "elasticache_auth" {
  secret_id = aws_secretsmanager_secret.elasticache_auth.id
  secret_string = jsonencode({
    auth_token = random_password.elasticache_auth_token.result
    host       = aws_elasticache_replication_group.concert.configuration_endpoint_address
    port       = 6379
    url        = "rediss://:${random_password.elasticache_auth_token.result}@${aws_elasticache_replication_group.concert.configuration_endpoint_address}:6379"
  })
}

# ============================================================================
# CLOUDWATCH ALARMS FOR ELASTICACHE
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "concert-redis-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alert when Redis CPU is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.concert.id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "concert-redis-memory-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Alert when Redis memory usage is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.concert.id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  alarm_name          = "concert-redis-evictions-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Alert when Redis evictions are high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.concert.id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_connections" {
  alarm_name          = "concert-redis-connections-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 65000
  alarm_description   = "Alert when Redis connections are high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.concert.id
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "elasticache_endpoint" {
  value       = aws_elasticache_replication_group.concert.configuration_endpoint_address
  description = "ElastiCache endpoint address"
}

output "elasticache_port" {
  value       = aws_elasticache_replication_group.concert.port
  description = "ElastiCache port"
}

output "elasticache_auth_secret_arn" {
  value       = aws_secretsmanager_secret.elasticache_auth.arn
  description = "ElastiCache auth token secret ARN"
}

output "elasticache_replication_group_id" {
  value       = aws_elasticache_replication_group.concert.id
  description = "ElastiCache replication group ID"
}

output "elasticache_reader_endpoint" {
  value       = aws_elasticache_replication_group.concert.reader_endpoint_address
  description = "ElastiCache reader endpoint address"
}
