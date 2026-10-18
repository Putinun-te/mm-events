#!/bin/bash
# Check existing EC2 instances and security for GitHub runners

echo "🔍 Checking existing EC2 instances..."
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running,stopped" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value|[0],PublicIpAddress,PrivateIpAddress]' \
  --output table

echo ""
echo "🔍 Checking EKS clusters and nodes..."
aws eks list-clusters --query 'clusters' --output table

for cluster in $(aws eks list-clusters --query 'clusters[]' --output text); do
  echo "EKS Cluster: $cluster"
  aws eks list-nodegroups --cluster-name $cluster --query 'nodegroups' --output table
done

echo ""
echo "🔒 Security Groups Analysis..."
aws ec2 describe-security-groups \
  --query 'SecurityGroups[].[GroupId,GroupName,Description]' \
  --output table

echo ""
echo "🔒 IAM Roles for runners..."
aws iam list-roles --query 'Roles[?contains(RoleName,`runner`)||contains(RoleName,`github`)||contains(RoleName,`eks`)].[RoleName,CreateDate]' --output table

echo ""
echo "⚠️  SECURITY RECOMMENDATIONS:"
echo "- Don't use EKS worker nodes as GitHub runners"
echo "- Create dedicated EC2 for runners"
echo "- Use separate security group with minimal access"
echo "- Use private subnets"