# VPC and Networking Setup
# Complete network infrastructure for Concert application

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "concert"
      ManagedBy   = "terraform"
      CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}

# ============================================================================
# VPC CONFIGURATION
# ============================================================================

resource "aws_vpc" "concert" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "concert-vpc-${var.environment}"
  }
}

# ============================================================================
# PUBLIC SUBNETS (API Gateway, NAT)
# ============================================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.concert.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "concert-public-subnet-1-${var.environment}"
    Type = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.concert.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "concert-public-subnet-2-${var.environment}"
    Type = "Public"
  }
}

# ============================================================================
# PRIVATE SUBNETS (Lambda, RDS, ElastiCache)
# ============================================================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.concert.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "concert-private-subnet-1-${var.environment}"
    Type = "Private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.concert.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "concert-private-subnet-2-${var.environment}"
    Type = "Private"
  }
}

# ============================================================================
# INTERNET GATEWAY
# ============================================================================

resource "aws_internet_gateway" "concert" {
  vpc_id = aws_vpc.concert.id

  tags = {
    Name = "concert-igw-${var.environment}"
  }
}

# ============================================================================
# NAT GATEWAY (For Lambda to reach internet via private subnets)
# ============================================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "concert-nat-eip-${var.environment}"
  }

  depends_on = [aws_internet_gateway.concert]
}

resource "aws_nat_gateway" "concert" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "concert-nat-${var.environment}"
  }

  depends_on = [aws_internet_gateway.concert]
}

# ============================================================================
# ROUTE TABLES
# ============================================================================

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.concert.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.concert.id
  }

  tags = {
    Name = "concert-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.concert.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.concert.id
  }

  tags = {
    Name = "concert-private-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# Lambda Security Group
resource "aws_security_group" "lambda" {
  name_prefix = "concert-lambda-"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.concert.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "concert-lambda-sg-${var.environment}"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "concert-rds-"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.concert.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "concert-rds-sg-${var.environment}"
  }
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {
  name_prefix = "concert-elasticache-"
  description = "Security group for ElastiCache"
  vpc_id      = aws_vpc.concert.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "concert-elasticache-sg-${var.environment}"
  }
}

# ============================================================================
# VPC ENDPOINTS (For private Lambda access to AWS services)
# ============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.concert.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "concert-s3-endpoint-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.concert.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "concert-dynamodb-endpoint-${var.environment}"
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "vpc_id" {
  value       = aws_vpc.concert.id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  description = "Private subnet IDs"
}

output "public_subnet_ids" {
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  description = "Public subnet IDs"
}

output "lambda_security_group_id" {
  value       = aws_security_group.lambda.id
  description = "Lambda security group ID"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS security group ID"
}

output "elasticache_security_group_id" {
  value       = aws_security_group.elasticache.id
  description = "ElastiCache security group ID"
}
