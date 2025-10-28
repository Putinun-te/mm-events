# Output the ALB DNS name
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.concert.dns_name
}

# Output the RDS endpoint
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.concert.endpoint
}

# Output the ECS cluster name
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.concert.name
}

# Output the backend service name
output "backend_service_name" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend.name
}

# Output the frontend service name
output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}

# Output the ECR repository URLs
output "backend_ecr_repository_url" {
  description = "ECR repository URL for backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repository_url" {
  description = "ECR repository URL for frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

# Output VPC information
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.concert.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.concert.cidr_block
}

# Output subnet information
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Output security group information
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# Output CloudWatch log group
output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.ecs.name
}

# Output access URLs
output "application_url" {
  description = "Application URL (frontend)"
  value       = "http://${aws_lb.concert.dns_name}"
}

output "api_url" {
  description = "API URL (backend)"
  value       = "http://${aws_lb.concert.dns_name}/api"
}
