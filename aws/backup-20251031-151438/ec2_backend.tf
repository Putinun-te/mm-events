# ============================================================================
# EC2 BACKEND INSTANCES - SINGAPORE (ap-southeast-1)
# Spring Boot Application Servers
# ============================================================================

# Data source for latest Amazon Linux 2023 AMI in Singapore
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security Group for Backend EC2 Instances
resource "aws_security_group" "backend_ec2" {
  name        = "${var.project_name}-backend-ec2-sg"
  description = "Security group for Concert backend EC2 instances"
  vpc_id      = aws_vpc.concert.id

  # HTTP from anywhere (for testing - restrict in production)
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for management
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-backend-ec2-sg"
    Environment = var.environment
  }
}

# Launch Template for Backend EC2 (for Auto Scaling)
resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro" # Free tier eligible

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.backend_ec2.id]

  user_data = base64encode(templatefile("${path.module}/user_data/backend_setup.sh", {
    region                    = var.aws_region
    rds_endpoint             = aws_db_instance.concert.endpoint
    rds_secret_arn           = aws_secretsmanager_secret.rds_credentials.arn
    elasticache_endpoint     = aws_elasticache_replication_group.concert.primary_endpoint_address
    elasticache_secret_arn   = aws_secretsmanager_secret.elasticache_auth.arn
    event_pictures_bucket    = aws_s3_bucket.event_pictures.id
    user_avatars_bucket      = aws_s3_bucket.user_avatars.id
    api_gateway_endpoint     = aws_apigatewayv2_api.file_upload.api_endpoint
  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-backend"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "${var.project_name}-backend-launch-template"
    Environment = var.environment
  }
}

# EC2 Instance 1 - Primary Backend (Singapore AZ 1)
resource "aws_instance" "backend_primary" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_1.id

  iam_instance_profile   = aws_iam_instance_profile.backend_ec2_profile.name
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]

  user_data = base64encode(templatefile("${path.module}/user_data/backend_setup.sh", {
    region                    = var.aws_region
    rds_endpoint             = aws_db_instance.concert.endpoint
    rds_secret_arn           = aws_secretsmanager_secret.rds_credentials.arn
    elasticache_endpoint     = aws_elasticache_replication_group.concert.primary_endpoint_address
    elasticache_secret_arn   = aws_secretsmanager_secret.elasticache_auth.arn
    event_pictures_bucket    = aws_s3_bucket.event_pictures.id
    user_avatars_bucket      = aws_s3_bucket.user_avatars.id
    api_gateway_endpoint     = aws_apigatewayv2_api.file_upload.api_endpoint
  }))

  monitoring = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-backend-primary"
    Environment = var.environment
    AZ          = "ap-southeast-1a"
    Role        = "Backend"
  }
}

# EC2 Instance 2 - Secondary Backend (Singapore AZ 2)
resource "aws_instance" "backend_secondary" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_2.id

  iam_instance_profile   = aws_iam_instance_profile.backend_ec2_profile.name
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]

  user_data = base64encode(templatefile("${path.module}/user_data/backend_setup.sh", {
    region                    = var.aws_region
    rds_endpoint             = aws_db_instance.concert.endpoint
    rds_secret_arn           = aws_secretsmanager_secret.rds_credentials.arn
    elasticache_endpoint     = aws_elasticache_replication_group.concert.primary_endpoint_address
    elasticache_secret_arn   = aws_secretsmanager_secret.elasticache_auth.arn
    event_pictures_bucket    = aws_s3_bucket.event_pictures.id
    user_avatars_bucket      = aws_s3_bucket.user_avatars.id
    api_gateway_endpoint     = aws_apigatewayv2_api.file_upload.api_endpoint
  }))

  monitoring = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-backend-secondary"
    Environment = var.environment
    AZ          = "ap-southeast-1b"
    Role        = "Backend"
  }
}

# Elastic IP for Primary Backend
resource "aws_eip" "backend_primary" {
  instance = aws_instance.backend_primary.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-backend-primary-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.concert]
}

# Elastic IP for Secondary Backend
resource "aws_eip" "backend_secondary" {
  instance = aws_instance.backend_secondary.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-backend-secondary-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.concert]
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "backend_primary_public_ip" {
  value       = aws_eip.backend_primary.public_ip
  description = "Public IP of primary backend instance"
}

output "backend_primary_private_ip" {
  value       = aws_instance.backend_primary.private_ip
  description = "Private IP of primary backend instance"
}

output "backend_secondary_public_ip" {
  value       = aws_eip.backend_secondary.public_ip
  description = "Public IP of secondary backend instance"
}

output "backend_secondary_private_ip" {
  value       = aws_instance.backend_secondary.private_ip
  description = "Private IP of secondary backend instance"
}

output "backend_primary_instance_id" {
  value       = aws_instance.backend_primary.id
  description = "Instance ID of primary backend"
}

output "backend_secondary_instance_id" {
  value       = aws_instance.backend_secondary.id
  description = "Instance ID of secondary backend"
}

output "backend_ami_id" {
  value       = data.aws_ami.amazon_linux_2023.id
  description = "AMI ID used for backend instances"
}

output "backend_security_group_id" {
  value       = aws_security_group.backend_ec2.id
  description = "Security group ID for backend instances"
}
