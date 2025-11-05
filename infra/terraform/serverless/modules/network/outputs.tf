output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_route_table_id" {
  description = "Route table ID for public subnets."
  value       = aws_route_table.public.id
}

output "private_subnet_route_table_id" {
  description = "Route table ID for private subnets."
  value       = aws_route_table.private.id
}
