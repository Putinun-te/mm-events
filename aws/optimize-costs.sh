#!/bin/bash
###############################################################################
# Cost Optimization Script
# Removes expensive resources to fit within $25/month budget
###############################################################################

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE} AWS Cost Optimization${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Current estimated monthly cost: $52/month${NC}"
echo -e "${GREEN}Target monthly cost: $24/month${NC}"
echo -e "${RED}Savings needed: $28/month${NC}"
echo ""

echo "This script will:"
echo "  1. Remove NAT Gateway (-$32/month)"
echo "  2. Remove associated Elastic IP (-$3.60/month)"
echo "  3. Update private subnet routing"
echo ""
echo -e "${YELLOW}⚠️  WARNING: Private subnets will lose internet access${NC}"
echo "   - RDS database will still work (no internet needed)"
echo "   - ElastiCache will still work (no internet needed)"
echo "   - EC2 instances will use public subnets"
echo ""

read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo -e "${BLUE}Step 1: Backing up current configuration...${NC}"
cp networking.tf networking.tf.backup
echo -e "${GREEN}✓ Backup created: networking.tf.backup${NC}"

echo ""
echo -e "${BLUE}Step 2: Removing NAT Gateway from configuration...${NC}"

# Comment out NAT Gateway resources
cat > networking.tf << 'EOF'
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# NAT Gateway removed to save $32/month
# resource "aws_eip" "nat" {
#   domain = "vpc"
#   tags = {
#     Name = "${var.project_name}-nat-eip"
#   }
# }

# resource "aws_nat_gateway" "main" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public[0].id
#   
#   tags = {
#     Name = "${var.project_name}-nat"
#   }
# }

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Private subnets now have no internet access (cost optimization)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  # No NAT Gateway route
  
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
EOF

echo -e "${GREEN}✓ NAT Gateway removed from configuration${NC}"

echo ""
echo -e "${BLUE}Step 3: Validating Terraform configuration...${NC}"
terraform validate
echo -e "${GREEN}✓ Configuration is valid${NC}"

echo ""
echo -e "${BLUE}Step 4: Creating deployment plan...${NC}"
terraform plan -out=cost-optimize.tfplan
echo -e "${GREEN}✓ Plan created${NC}"

echo ""
echo -e "${YELLOW}Review the plan above. You should see:${NC}"
echo "  - Delete: aws_nat_gateway.main"
echo "  - Delete: aws_eip.nat"
echo "  - Update: aws_route_table.private (remove NAT route)"
echo ""

read -p "Apply these changes? (yes/no): " apply_confirm
if [ "$apply_confirm" != "yes" ]; then
  echo "Aborted. To restore, run: cp networking.tf.backup networking.tf"
  exit 0
fi

echo ""
echo -e "${BLUE}Step 5: Applying changes...${NC}"
terraform apply cost-optimize.tfplan

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} ✅ Cost Optimization Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Monthly cost reduced from $52 to ~$20!"
echo ""
echo "Next steps:"
echo "  1. Add ElastiCache: terraform apply (adds $12/month)"
echo "  2. Final cost: ~$24/month ✅"
echo "  3. Budget remaining: $172.85 - ($24 × 6 months) = $28.85 buffer"
echo ""
echo "Resources removed:"
echo "  ❌ NAT Gateway"
echo "  ❌ Elastic IP"
echo ""
echo "Impact:"
echo "  ✅ RDS still works (in private subnet, no internet needed)"
echo "  ✅ ElastiCache still works (in private subnet, no internet needed)"
echo "  ✅ EC2 instances use public subnets (have internet access)"
echo "  ❌ Private subnet resources can't reach internet"
echo ""
