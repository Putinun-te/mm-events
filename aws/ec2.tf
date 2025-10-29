# EC2 Instances Configuration
# This module creates EC2 instances for deploying the Concert application

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for EC2 Instances
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for Concert EC2 instances"
  vpc_id      = aws_vpc.concert.id

  # SSH access from anywhere (restrict in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend API port (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend dev server port (3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker registry (optional)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# IAM Policy for EC2 to access ECR
resource "aws_iam_role_policy" "ec2_ecr_policy" {
  name = "${var.project_name}-ec2-ecr-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# User data script for EC2 initialization
locals {
  user_data_script = base64encode(<<-EOF
#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Start Docker daemon
systemctl start docker
systemctl enable docker

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure CloudWatch logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWLOG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/docker-events.log",
            "log_group_name": "/concert/ec2/docker",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/concert/ec2/system",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWLOG

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Log that setup is complete
echo "EC2 setup completed at $(date)" > /var/log/setup-complete.log
EOF
)
}

# Backend EC2 Instance
resource "aws_instance" "backend" {
  count                = var.enable_ec2_backend ? 1 : 0
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = aws_key_pair.deployer.key_name

  # Launch in public subnet
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # User data script
  user_data = local.user_data_script

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ec2_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  monitoring = true

  tags = {
    Name = "${var.project_name}-backend-ec2"
    Role = "backend"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }

  depends_on = [aws_internet_gateway.concert]
}

# Frontend EC2 Instance
resource "aws_instance" "frontend" {
  count                = var.enable_ec2_frontend ? 1 : 0
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = aws_key_pair.deployer.key_name

  # Launch in public subnet (different AZ)
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # User data script
  user_data = local.user_data_script

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ec2_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  monitoring = true

  tags = {
    Name = "${var.project_name}-frontend-ec2"
    Role = "frontend"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }

  depends_on = [aws_internet_gateway.concert]
}

# SSH Key Pair for EC2 access
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-deployer-key"
  public_key = var.ec2_public_key != "" ? var.ec2_public_key : tls_private_key.generated.public_key_openssh

  tags = {
    Name = "${var.project_name}-deployer-key"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Generate SSH key pair if not provided
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save generated private key
resource "local_file" "private_key" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# Elastic IPs for EC2 instances (for static public IPs)
resource "aws_eip" "backend" {
  count    = var.enable_ec2_backend && var.associate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.backend[0].id

  tags = {
    Name = "${var.project_name}-backend-eip"
  }

  depends_on = [aws_internet_gateway.concert]

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_eip" "frontend" {
  count    = var.enable_ec2_frontend && var.associate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.frontend[0].id

  tags = {
    Name = "${var.project_name}-frontend-eip"
  }

  depends_on = [aws_internet_gateway.concert]

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ec2_docker" {
  count             = var.enable_ec2_backend || var.enable_ec2_frontend ? 1 : 0
  name              = "/concert/ec2/docker"
  retention_in_days = 7

  tags = {
    Name = "concert-ec2-docker-logs"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_cloudwatch_log_group" "ec2_system" {
  count             = var.enable_ec2_backend || var.enable_ec2_frontend ? 1 : 0
  name              = "/concert/ec2/system"
  retention_in_days = 7

  tags = {
    Name = "concert-ec2-system-logs"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}
