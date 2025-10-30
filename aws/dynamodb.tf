# DynamoDB Tables Configuration
# High-performance NoSQL database for Concert microservices

# ============================================================================
# DYNAMODB TABLE: SESSION TOKENS
# ============================================================================

resource "aws_dynamodb_table" "session_tokens" {
  name           = "concert-session-tokens-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 5
  write_capacity_units = var.environment == "prod" ? null : 5
  hash_key       = "token_id"
  range_key      = "user_id"

  attribute {
    name = "token_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "expires_at"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "user_id-expires_at-index"
    hash_key        = "user_id"
    range_key       = "expires_at"
    projection_type = "ALL"
    read_capacity_units  = var.environment == "prod" ? null : 5
    write_capacity_units = var.environment == "prod" ? null : 5
  }

  tags = {
    Name = "concert-session-tokens-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: EVENT DETAILS CACHE
# ============================================================================

resource "aws_dynamodb_table" "event_details" {
  name           = "concert-event-details-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 10
  write_capacity_units = var.environment == "prod" ? null : 10
  hash_key       = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "created_at-index"
    hash_key        = "created_at"
    projection_type = "ALL"
    read_capacity_units  = var.environment == "prod" ? null : 5
    write_capacity_units = var.environment == "prod" ? null : 5
  }

  tags = {
    Name = "concert-event-details-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: BOOKING CACHE
# ============================================================================

resource "aws_dynamodb_table" "booking_cache" {
  name           = "concert-booking-cache-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 10
  write_capacity_units = var.environment == "prod" ? null : 10
  hash_key       = "booking_id"

  attribute {
    name = "booking_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "user_id-index"
    hash_key        = "user_id"
    projection_type = "ALL"
    read_capacity_units  = var.environment == "prod" ? null : 5
    write_capacity_units = var.environment == "prod" ? null : 5
  }

  tags = {
    Name = "concert-booking-cache-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: USER PREFERENCES
# ============================================================================

resource "aws_dynamodb_table" "user_preferences" {
  name           = "concert-user-preferences-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 5
  write_capacity_units = var.environment == "prod" ? null : 5
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Name = "concert-user-preferences-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: FILE METADATA
# ============================================================================

resource "aws_dynamodb_table" "file_metadata" {
  name           = "concert-file-metadata-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 5
  write_capacity_units = var.environment == "prod" ? null : 5
  hash_key       = "file_key"

  attribute {
    name = "file_key"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "user_id-index"
    hash_key        = "user_id"
    projection_type = "ALL"
    read_capacity_units  = var.environment == "prod" ? null : 5
    write_capacity_units = var.environment == "prod" ? null : 5
  }

  tags = {
    Name = "concert-file-metadata-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: EMAIL LOG
# ============================================================================

resource "aws_dynamodb_table" "email_log" {
  name           = "concert-email-log-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 10
  write_capacity_units = var.environment == "prod" ? null : 10
  hash_key       = "email_id"

  attribute {
    name = "email_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "created_at-index"
    hash_key        = "created_at"
    projection_type = "ALL"
    read_capacity_units  = var.environment == "prod" ? null : 5
    write_capacity_units = var.environment == "prod" ? null : 5
  }

  tags = {
    Name = "concert-email-log-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: PAYMENT CACHE
# ============================================================================

resource "aws_dynamodb_table" "payment_cache" {
  name           = "concert-payment-cache-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 10
  write_capacity_units = var.environment == "prod" ? null : 10
  hash_key       = "payment_id"

  attribute {
    name = "payment_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "concert-payment-cache-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: ANALYTICS EVENTS
# ============================================================================

resource "aws_dynamodb_table" "analytics_events" {
  name           = "concert-analytics-events-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"  # Always on-demand for analytics
  hash_key       = "event_type"
  range_key      = "timestamp"

  attribute {
    name = "event_type"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "user_id-timestamp-index"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  tags = {
    Name = "concert-analytics-events-${var.environment}"
  }
}

# ============================================================================
# DYNAMODB TABLE: AUDIT CACHE
# ============================================================================

resource "aws_dynamodb_table" "audit_cache" {
  name           = "concert-audit-cache-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "audit_id"

  attribute {
    name = "audit_id"
    type = "S"
  }

  attribute {
    name = "resource_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "resource_id-index"
    hash_key        = "resource_id"
    projection_type = "ALL"
  }

  tags = {
    Name = "concert-audit-cache-${var.environment}"
  }
}

# ============================================================================
# AUTO SCALING FOR DYNAMODB (Production environment)
# ============================================================================

resource "aws_appautoscaling_target" "event_details_write" {
  count              = var.environment == "prod" ? 1 : 0
  max_capacity       = 40
  min_capacity       = 10
  resource_id        = "table/${aws_dynamodb_table.event_details.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "event_details_write" {
  count              = var.environment == "prod" ? 1 : 0
  policy_name        = "concert-event-details-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.event_details_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.event_details_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.event_details_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0

    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ============================================================================
# CLOUDWATCH ALARMS FOR DYNAMODB
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "dynamodb_user_errors" {
  alarm_name          = "concert-dynamodb-user-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when DynamoDB user errors are high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.session_tokens.name
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "dynamodb_tables" {
  value = {
    session_tokens   = aws_dynamodb_table.session_tokens.name
    event_details    = aws_dynamodb_table.event_details.name
    booking_cache    = aws_dynamodb_table.booking_cache.name
    user_preferences = aws_dynamodb_table.user_preferences.name
    file_metadata    = aws_dynamodb_table.file_metadata.name
    email_log        = aws_dynamodb_table.email_log.name
    payment_cache    = aws_dynamodb_table.payment_cache.name
    analytics_events = aws_dynamodb_table.analytics_events.name
    audit_cache      = aws_dynamodb_table.audit_cache.name
  }
  description = "All DynamoDB table names"
}
