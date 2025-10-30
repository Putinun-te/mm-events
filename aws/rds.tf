# RDS MySQL Database Configuration
# Production-ready MySQL database for Concert application

# ============================================================================
# RDS DATABASE SUBNET GROUP
# ============================================================================

resource "aws_db_subnet_group" "concert" {
  name       = "concert-db-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "concert-db-subnet-group-${var.environment}"
  }
}

# ============================================================================
# RDS MYSQL INSTANCE
# ============================================================================

resource "aws_db_instance" "concert" {
  identifier              = "concert-mysql-${var.environment}"
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  storage_encrypted       = true
  storage_type            = "gp3"
  
  # Credentials
  db_name  = var.rds_database_name
  username = var.rds_username
  password = random_password.rds_password.result
  
  # Networking
  db_subnet_group_name   = aws_db_subnet_group.concert.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  
  # Backups & Maintenance
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  multi_az               = var.environment == "prod" ? true : false
  
  # High Availability
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = "concert-mysql-final-snapshot-${var.environment}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Monitoring
  performance_insights_enabled = var.environment == "prod" ? true : false
  monitor_interval            = var.environment == "prod" ? 60 : 0
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn
  
  # Advanced Options
  parameter_group_name       = aws_db_parameter_group.concert.name
  option_group_name          = aws_db_option_group.concert.name
  deletion_protection        = var.environment == "prod" ? true : false
  enable_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = {
    Name = "concert-mysql-${var.environment}"
  }
}

# ============================================================================
# RDS PARAMETER GROUP (Custom MySQL configurations)
# ============================================================================

resource "aws_db_parameter_group" "concert" {
  family      = "mysql8.0"
  name_prefix = "concert-"
  description = "Concert MySQL parameters"

  # Performance
  parameter {
    name  = "max_connections"
    value = "1000"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  # Security
  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  tags = {
    Name = "concert-mysql-params-${var.environment}"
  }
}

# ============================================================================
# RDS OPTION GROUP
# ============================================================================

resource "aws_db_option_group" "concert" {
  name_prefix              = "concert-"
  option_group_description = "Concert MySQL options"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = {
    Name = "concert-mysql-options-${var.environment}"
  }
}

# ============================================================================
# RDS ENHANCED MONITORING ROLE
# ============================================================================

resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "concert-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================================
# RDS BACKUP CONFIGURATION
# ============================================================================

resource "aws_db_snapshot_copy_retention" "concert" {
  source_db_snapshot_identifier = aws_db_instance.concert.id
  retention_days                = 30

  tags = {
    Name = "concert-snapshot-copy-${var.environment}"
  }
}

# ============================================================================
# SECRETS MANAGER - RDS CREDENTIALS
# ============================================================================

resource "random_password" "rds_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name_prefix             = "concert-rds-"
  recovery_window_in_days = 7

  tags = {
    Name = "concert-rds-credentials-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.rds_username
    password = random_password.rds_password.result
    engine   = "mysql"
    host     = aws_db_instance.concert.address
    port     = 3306
    dbname   = var.rds_database_name
    url      = "mysql://${var.rds_username}:${random_password.rds_password.result}@${aws_db_instance.concert.address}:3306/${var.rds_database_name}"
  })
}

# ============================================================================
# READ REPLICA (For scaling read operations)
# ============================================================================

resource "aws_db_instance" "read_replica" {
  count              = var.environment == "prod" ? 1 : 0
  identifier         = "concert-mysql-read-replica-${var.environment}"
  replicate_source_db = aws_db_instance.concert.identifier
  instance_class     = var.rds_instance_class
  storage_encrypted  = true
  publicly_accessible = false

  tags = {
    Name = "concert-mysql-read-replica-${var.environment}"
  }
}

# ============================================================================
# CLOUDWATCH ALARMS FOR RDS
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "concert-rds-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.concert.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  alarm_name          = "concert-rds-connections-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 800
  alarm_description   = "Alert when database connections are high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.concert.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "concert-rds-storage-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120  # 5GB in bytes
  alarm_description   = "Alert when free storage space is low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.concert.id
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "rds_endpoint" {
  value       = aws_db_instance.concert.endpoint
  description = "RDS endpoint address"
  sensitive   = true
}

output "rds_address" {
  value       = aws_db_instance.concert.address
  description = "RDS instance address"
}

output "rds_port" {
  value       = aws_db_instance.concert.port
  description = "RDS port"
}

output "rds_database_name" {
  value       = aws_db_instance.concert.db_name
  description = "RDS database name"
}

output "rds_credentials_secret_arn" {
  value       = aws_secretsmanager_secret.rds_credentials.arn
  description = "RDS credentials secret ARN"
}
