variable "name" {
  description = "Prefix for alarm and dashboard names."
  type        = string
}

variable "region" {
  description = "AWS region for CloudWatch dashboard."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name for metrics."
  type        = string
  default     = ""
}

variable "api_id" {
  description = "API Gateway HTTP API ID."
  type        = string
  default     = ""
}

variable "api_stage_name" {
  description = "Stage name monitored for API Gateway metrics."
  type        = string
  default     = "prod"
}

variable "db_instance_identifier" {
  description = "RDS instance identifier."
  type        = string
  default     = ""
}

variable "alarm_actions" {
  description = "ARNs notified when alarms go into ALARM state."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "ARNs notified when alarms recover."
  type        = list(string)
  default     = []
}

variable "lambda_error_threshold" {
  description = "Lambda error threshold per evaluation window."
  type        = number
  default     = 1
}

variable "lambda_error_period" {
  description = "Period (seconds) for Lambda error metric."
  type        = number
  default     = 300
}

variable "lambda_error_evaluation_periods" {
  description = "Evaluation periods for Lambda error alarm."
  type        = number
  default     = 1
}

variable "lambda_error_datapoints_to_alarm" {
  description = "Datapoints to alarm for Lambda error alarm."
  type        = number
  default     = 1
}

variable "api_5xx_threshold" {
  description = "5XX error count threshold."
  type        = number
  default     = 1
}

variable "api_5xx_period" {
  description = "Period (seconds) for API 5XX metric."
  type        = number
  default     = 300
}

variable "api_5xx_evaluation_periods" {
  description = "Evaluation periods for API 5XX alarm."
  type        = number
  default     = 1
}

variable "api_5xx_datapoints_to_alarm" {
  description = "Datapoints to alarm for API 5XX alarm."
  type        = number
  default     = 1
}

variable "db_cpu_threshold" {
  description = "CPU utilization threshold percentage."
  type        = number
  default     = 70
}

variable "db_cpu_period" {
  description = "Period (seconds) for DB CPU metric."
  type        = number
  default     = 300
}

variable "db_cpu_evaluation_periods" {
  description = "Evaluation periods for DB CPU alarm."
  type        = number
  default     = 3
}

variable "db_cpu_datapoints_to_alarm" {
  description = "Datapoints to alarm for DB CPU alarm."
  type        = number
  default     = 2
}

variable "enable_dashboard" {
  description = "Create a CloudWatch dashboard summarizing the stack."
  type        = bool
  default     = true
}
