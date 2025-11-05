output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53)"
  value       = aws_lb.this.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "api_endpoint_http" {
  description = "HTTP API endpoint (use HTTPS in production)"
  value       = "http://${aws_lb.this.dns_name}"
}

output "api_endpoint_https" {
  description = "HTTPS API endpoint (if certificate configured)"
  value       = var.acm_certificate_arn != "" ? "https://${aws_lb.this.dns_name}" : "Certificate not configured - using HTTP"
}
