###############################################################################
# CloudWatch Monitoring, Dashboards, and Alarms
###############################################################################

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/application"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-app-logs"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Database Logs
resource "aws_cloudwatch_log_group" "database" {
  name              = "/aws/${var.project_name}/database"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-db-logs"
    Environment = var.environment
  }
}

###############################################################################
# CloudWatch Alarms
###############################################################################

# EC2 High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_high_cpu" {
  alarm_name          = "${var.project_name}-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []  # Add SNS topic ARN for notifications

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name = "${var.project_name}-ec2-cpu-alarm"
  }
}

# RDS High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "RDS CPU utilization is too high"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-rds-cpu-alarm"
  }
}

# RDS Low Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000000000"  # 2GB in bytes
  alarm_description   = "RDS free storage space is low"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-rds-storage-alarm"
  }
}

# RDS High Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "${var.project_name}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Too many database connections"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-rds-connections-alarm"
  }
}

# ElastiCache High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "redis_high_cpu" {
  alarm_name          = "${var.project_name}-redis-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Redis CPU utilization is too high"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.id
  }

  tags = {
    Name = "${var.project_name}-redis-cpu-alarm"
  }
}

# ElastiCache Low Memory Alarm
resource "aws_cloudwatch_metric_alarm" "redis_low_memory" {
  alarm_name          = "${var.project_name}-redis-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"  # 100MB
  alarm_description   = "Redis freeable memory is low"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.id
  }

  tags = {
    Name = "${var.project_name}-redis-memory-alarm"
  }
}

# ElastiCache Cache Hit Rate Alarm
resource "aws_cloudwatch_metric_alarm" "redis_low_hit_rate" {
  alarm_name          = "${var.project_name}-redis-low-hit-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # 80% hit rate
  alarm_description   = "Cache hit rate is below optimal"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis.id
  }

  tags = {
    Name = "${var.project_name}-redis-hitrate-alarm"
  }
}

###############################################################################
# CloudWatch Dashboard
###############################################################################

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # EC2 CPU Widget
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "EC2 CPU" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      # RDS Metrics Widget
      {
        type = "metric"
        x    = 12
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "RDS CPU" }],
            [".", "DatabaseConnections", { stat = "Average", label = "DB Connections" }],
            [".", "FreeStorageSpace", { stat = "Average", label = "Free Storage", yAxis = "right" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Performance"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      # ElastiCache Metrics Widget
      {
        type = "metric"
        x    = 0
        y    = 6
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", { stat = "Average", label = "Redis CPU" }],
            [".", "CacheHitRate", { stat = "Average", label = "Cache Hit Rate" }],
            [".", "CurrConnections", { stat = "Average", label = "Connections" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ElastiCache Performance"
        }
      },
      # Network Traffic Widget
      {
        type = "metric"
        x    = 12
        y    = 6
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Network Traffic"
        }
      },
      # Auto Scaling Widget
      {
        type = "metric"
        x    = 0
        y    = 12
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", { stat = "Average", label = "Desired" }],
            [".", "GroupInServiceInstances", { stat = "Average", label = "In Service" }],
            [".", "GroupMinSize", { stat = "Average", label = "Min" }],
            [".", "GroupMaxSize", { stat = "Average", label = "Max" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Auto Scaling Status"
        }
      },
      # S3 Storage Widget
      {
        type = "metric"
        x    = 12
        y    = 12
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", aws_s3_bucket.event_pictures.id, "StorageType", "StandardStorage"],
            ["...", aws_s3_bucket.user_avatars.id, ".", "."]
          ]
          period = 86400
          stat   = "Average"
          region = var.aws_region
          title  = "S3 Storage Usage"
        }
      }
    ]
  })
}

# Output Dashboard URL
output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "cloudwatch_log_group_application" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "cloudwatch_log_group_database" {
  description = "Database log group name"
  value       = aws_cloudwatch_log_group.database.name
}
