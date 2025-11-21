#!/bin/bash

echo "🏷️ Renaming EC2 instances..."

# Rename first EKS node to Backend
aws ec2 create-tags --region ap-southeast-1 \
  --resources i-021328b8eb58f98f1 \
  --tags Key=Name,Value="Concert-Backend-Node-1"

# Rename second EKS node to Backend  
aws ec2 create-tags --region ap-southeast-1 \
  --resources i-0a8bcda9c7e5f1af9 \
  --tags Key=Name,Value="Concert-Backend-Node-2"

echo "✅ EC2 instances renamed to Concert-Backend-Node-1 and Concert-Backend-Node-2"