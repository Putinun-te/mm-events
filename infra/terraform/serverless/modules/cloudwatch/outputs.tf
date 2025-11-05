output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = try(aws_cloudwatch_dashboard.this[0].dashboard_name, null)
}
