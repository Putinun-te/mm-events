locals {
  metrics = [
    {
      id          = "lambdaErrors"
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      stat        = "Sum"
      dimensions  = { FunctionName = var.lambda_function_name }
    },
    {
      id          = "lambdaDuration"
      namespace   = "AWS/Lambda"
      metric_name = "Duration"
      stat        = "Average"
      dimensions  = { FunctionName = var.lambda_function_name }
    },
    {
      id          = "api5xx"
      namespace   = "AWS/ApiGateway"
      metric_name = "5XXError"
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id, Stage = var.api_stage_name }
    },
    {
      id          = "apiLatency"
      namespace   = "AWS/ApiGateway"
      metric_name = "Latency"
      stat        = "Average"
      dimensions  = { ApiId = var.api_id, Stage = var.api_stage_name }
    },
    {
      id          = "dbCPU"
      namespace   = "AWS/RDS"
      metric_name = "CPUUtilization"
      stat        = "Average"
      dimensions  = { DBInstanceIdentifier = var.db_instance_identifier }
    }
  ]
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.lambda_function_name == "" ? 0 : 1
  alarm_name          = "${var.name}-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.lambda_error_evaluation_periods
  datapoints_to_alarm = var.lambda_error_datapoints_to_alarm
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.lambda_error_period
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Lambda errors exceed threshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.name}-api-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.api_5xx_evaluation_periods
  datapoints_to_alarm = var.api_5xx_datapoints_to_alarm
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = var.api_5xx_period
  statistic           = "Sum"
  threshold           = var.api_5xx_threshold
  alarm_description   = "API Gateway 5XX errors exceed threshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    ApiId = var.api_id
    Stage = var.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "${var.name}-db-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.db_cpu_evaluation_periods
  datapoints_to_alarm = var.db_cpu_datapoints_to_alarm
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.db_cpu_period
  statistic           = "Average"
  threshold           = var.db_cpu_threshold
  alarm_description   = "RDS CPU utilization above threshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${var.name}-overview"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title   = "Lambda"
          region  = var.region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Errors", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name]
          ]
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title   = "API Gateway"
          region  = var.region
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiId", var.api_id, "Stage", var.api_stage_name],
            ["AWS/ApiGateway", "5XXError", "ApiId", var.api_id, "Stage", var.api_stage_name],
            ["AWS/ApiGateway", "Latency", "ApiId", var.api_id, "Stage", var.api_stage_name]
          ]
          view    = "timeSeries"
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title   = "RDS"
          region  = var.region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_identifier]
          ]
          view = "timeSeries"
        }
      }
    ]
  })
}
