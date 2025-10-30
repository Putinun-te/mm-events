# Messaging Services Configuration
# SNS for notifications and SQS for async processing

# ============================================================================
# SNS TOPICS
# ============================================================================

# Notifications Topic
resource "aws_sns_topic" "notifications" {
  name              = "concert-notifications-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "concert-notifications-${var.environment}"
  }
}

resource "aws_sns_topic_policy" "notifications" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.notifications.arn
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "SNS:*"
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

# Email Topic
resource "aws_sns_topic" "email" {
  name              = "concert-email-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "concert-email-${var.environment}"
  }
}

# SMS Topic
resource "aws_sns_topic" "sms" {
  name              = "concert-sms-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "concert-sms-${var.environment}"
  }
}

# Events Topic (for internal event broadcasting)
resource "aws_sns_topic" "events" {
  name              = "concert-events-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "concert-events-${var.environment}"
  }
}

# Alerts Topic
resource "aws_sns_topic" "alerts" {
  name              = "concert-alerts-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "concert-alerts-${var.environment}"
  }
}

# ============================================================================
# SQS QUEUES
# ============================================================================

# Email Processing Queue
resource "aws_sqs_queue" "email_queue" {
  name                       = "concert-email-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144  # 256 KB
  message_retention_seconds  = 345600  # 4 days
  visibility_timeout_seconds = 300     # 5 minutes
  kms_master_key_id          = "alias/aws/sqs"

  tags = {
    Name = "concert-email-queue-${var.environment}"
  }
}

resource "aws_sqs_queue" "email_queue_dlq" {
  name              = "concert-email-queue-dlq-${var.environment}"
  message_retention_seconds = 1209600  # 14 days
  kms_master_key_id = "alias/aws/sqs"

  tags = {
    Name = "concert-email-queue-dlq-${var.environment}"
  }
}

resource "aws_sqs_queue_redrive_policy" "email_queue" {
  queue_url              = aws_sqs_queue.email_queue.id
  dead_letter_target_arn = aws_sqs_queue.email_queue_dlq.arn
  max_receive_count      = 3
}

# Notification Queue
resource "aws_sqs_queue" "notification_queue" {
  name                       = "concert-notification-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 300
  kms_master_key_id          = "alias/aws/sqs"

  tags = {
    Name = "concert-notification-queue-${var.environment}"
  }
}

# Refund Processing Queue
resource "aws_sqs_queue" "refund_queue" {
  name                       = "concert-refund-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 900  # 15 minutes for refund processing
  kms_master_key_id          = "alias/aws/sqs"

  tags = {
    Name = "concert-refund-queue-${var.environment}"
  }
}

# Analytics Queue
resource "aws_sqs_queue" "analytics_queue" {
  name                       = "concert-analytics-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 604800  # 7 days
  visibility_timeout_seconds = 300
  kms_master_key_id          = "alias/aws/sqs"

  receive_message_wait_time_seconds = 20  # Long polling

  tags = {
    Name = "concert-analytics-queue-${var.environment}"
  }
}

# ============================================================================
# SQS QUEUE POLICIES
# ============================================================================

resource "aws_sqs_queue_policy" "email_queue" {
  queue_url = aws_sqs_queue.email_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.email_queue.arn
      }
    ]
  })
}

# ============================================================================
# SNS SUBSCRIPTIONS (SNS -> SQS)
# ============================================================================

resource "aws_sns_topic_subscription" "email_to_queue" {
  topic_arn            = aws_sns_topic.email.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.email_queue.arn
  raw_message_delivery = true
}

resource "aws_sqs_queue_policy" "email_queue_sns" {
  queue_url = aws_sqs_queue.email_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.email_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.email.arn
          }
        }
      }
    ]
  })
}

# ============================================================================
# CLOUDWATCH ALARMS FOR MESSAGING
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "sqs_email_queue_age" {
  alarm_name          = "concert-email-queue-age-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 300  # 5 minutes
  alarm_description   = "Alert when email queue message age is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.email_queue.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sns_email_failures" {
  alarm_name          = "concert-sns-email-failures-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when SNS email failures occur"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TopicName = aws_sns_topic.email.name
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}

# ============================================================================
# OUTPUTS
# ============================================================================

output "sns_topics" {
  value = {
    notifications = aws_sns_topic.notifications.arn
    email         = aws_sns_topic.email.arn
    sms           = aws_sns_topic.sms.arn
    events        = aws_sns_topic.events.arn
    alerts        = aws_sns_topic.alerts.arn
  }
  description = "All SNS topic ARNs"
}

output "sqs_queues" {
  value = {
    email_url        = aws_sqs_queue.email_queue.url
    email_arn        = aws_sqs_queue.email_queue.arn
    notification_url = aws_sqs_queue.notification_queue.url
    refund_url       = aws_sqs_queue.refund_queue.url
    analytics_url    = aws_sqs_queue.analytics_queue.url
  }
  description = "All SQS queue details"
}
