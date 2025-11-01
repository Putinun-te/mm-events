#!/bin/bash
# AWS IAM Quick Commands - Save this for reference
# Concert Application IAM Groups - AWS CLI Command Cheatsheet

# ═══════════════════════════════════════════════════════════════════════════
# GROUP MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# List all groups
aws iam list-groups

# List only concert groups
aws iam list-groups --query 'Groups[?contains(GroupName, `concert`)].GroupName'

# Get group details
aws iam get-group --group-name concert-developers

# List all policies for a group
aws iam list-group-policies --group-name concert-developers

# View a specific policy
aws iam get-group-policy --group-name concert-developers --policy-name DeveloperS3Policy

# ═══════════════════════════════════════════════════════════════════════════
# USER MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# Add user to group
aws iam add-user-to-group --group-name concert-developers --user-name john.doe

# Remove user from group
aws iam remove-user-from-group --group-name concert-developers --user-name john.doe

# List groups for a user
aws iam list-groups-for-user --user-name john.doe

# Create a new IAM user
aws iam create-user --user-name john.doe

# List all users
aws iam list-users

# Get specific user details
aws iam get-user --user-name john.doe

# Delete a user (must remove from all groups first)
aws iam delete-user --user-name john.doe

# ═══════════════════════════════════════════════════════════════════════════
# ACCESS KEY MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# Create access keys for a user
aws iam create-access-key --user-name john.doe

# List access keys for a user
aws iam list-access-keys --user-name john.doe

# Delete an access key
aws iam delete-access-key --user-name john.doe --access-key-id AKIAIOSFODNN7EXAMPLE

# Update access key status (deactivate)
aws iam update-access-key --user-name john.doe --access-key-id AKIAIOSFODNN7EXAMPLE --status Inactive

# ═══════════════════════════════════════════════════════════════════════════
# PASSWORD MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# Create login profile (console password)
aws iam create-login-profile --user-name john.doe --password TempPassword123! --password-reset-required

# Change password
aws iam update-login-profile --user-name john.doe --password NewPassword456!

# Delete login profile
aws iam delete-login-profile --user-name john.doe

# ═══════════════════════════════════════════════════════════════════════════
# MFA MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# List MFA devices for a user
aws iam list-mfa-devices --user-name john.doe

# Enable MFA device
aws iam enable-mfa-device --user-name john.doe --serial-number arn:aws:iam::123456789012:mfa/john.doe --authentication-code1 123456 --authentication-code2 789012

# Deactivate MFA device
aws iam deactivate-mfa-device --user-name john.doe --serial-number arn:aws:iam::123456789012:mfa/john.doe

# ═══════════════════════════════════════════════════════════════════════════
# BULK OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════

# Add multiple users to a group (from text file with usernames, one per line)
cat users.txt | xargs -I {} aws iam add-user-to-group --group-name concert-developers --user-name {}

# List all users with their groups
aws iam list-users --query 'Users[].UserName' --output text | tr '\t' '\n' | while read user; do
  echo "User: $user"
  aws iam list-groups-for-user --user-name $user --query 'Groups[].GroupName' --output text
  echo ""
done

# Remove all users from a group
aws iam get-group --group-name concert-developers --query 'Users[].UserName' --output text | tr '\t' '\n' | while read user; do
  aws iam remove-user-from-group --group-name concert-developers --user-name $user
done

# ═══════════════════════════════════════════════════════════════════════════
# VERIFICATION & TESTING
# ═══════════════════════════════════════════════════════════════════════════

# Verify user has correct permissions (test S3 access)
aws s3 ls --profile john.doe

# Test IAM access
aws iam list-groups --profile john.doe

# Check current AWS identity
aws sts get-caller-identity

# Get current user
aws iam get-user

# ═══════════════════════════════════════════════════════════════════════════
# POLICY MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# View policy details (formatted as JSON)
aws iam get-group-policy --group-name concert-developers --policy-name DeveloperS3Policy --query 'PolicyDocument' | jq .

# Update a policy
aws iam put-group-policy \
  --group-name concert-developers \
  --policy-name DeveloperS3Policy \
  --policy-document file://new-policy.json

# Delete a policy from a group
aws iam delete-group-policy --group-name concert-developers --policy-name DeveloperSelfServicePolicy

# ═══════════════════════════════════════════════════════════════════════════
# USEFUL QUERIES
# ═══════════════════════════════════════════════════════════════════════════

# List all groups and their user counts
aws iam list-groups --query 'Groups[*].[GroupName,length(GroupName)]' --output table

# Find all users without MFA
aws iam list-users --query 'Users[*].UserName' --output text | while read user; do
  mfa_count=$(aws iam list-mfa-devices --user-name $user --query 'MFADevices[].DeviceName' --output text | wc -w)
  if [ $mfa_count -eq 0 ]; then
    echo "No MFA: $user"
  fi
done

# List users with access keys
aws iam list-users --query 'Users[*].UserName' --output text | while read user; do
  keys=$(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].AccessKeyId' --output text)
  if [ ! -z "$keys" ]; then
    echo "Access keys for $user: $keys"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
# ENVIRONMENT-SPECIFIC COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

# Using AWS profiles (add to ~/.aws/config)
# [profile john-dev]
# role_arn = arn:aws:iam::123456789012:role/concert-developer
# source_profile = default

# Then use:
aws iam list-groups --profile john-dev

# Switch to a different profile
export AWS_PROFILE=john-dev
aws iam list-groups  # Uses john-dev profile

# ═══════════════════════════════════════════════════════════════════════════
# TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════════

# Check if user exists
aws iam get-user --user-name john.doe 2>&1 | grep -q "NoSuchEntity" && echo "User not found" || echo "User exists"

# Check if user is in group
aws iam get-group --group-name concert-developers --query "Users[?UserName=='john.doe']" --output text | grep -q john.doe && echo "User is in group" || echo "User not in group"

# Get policy details in readable format
aws iam get-group-policy --group-name concert-developers --policy-name DeveloperS3Policy --query 'PolicyDocument' | python3 -m json.tool

# Test policy simulation (see what a user can do)
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/john.doe \
  --action-names s3:GetObject s3:PutObject \
  --resource-arns arn:aws:s3:::concert-dev-bucket/*

# ═══════════════════════════════════════════════════════════════════════════
# AWS CLI ALIASES (add to ~/.zshrc or ~/.bashrc)
# ═══════════════════════════════════════════════════════════════════════════

# Add these aliases for faster commands:
# alias iamgroups='aws iam list-groups --query "Groups[?contains(GroupName, \`concert\`)].GroupName"'
# alias iamgroups-dev='aws iam get-group --group-name concert-developers --query "Users[].UserName"'
# alias iamgroups-test='aws iam get-group --group-name concert-testers --query "Users[].UserName"'
# alias iamgroups-deploy='aws iam get-group --group-name concert-deployment --query "Users[].UserName"'
# alias iamgroups-admin='aws iam get-group --group-name concert-admins --query "Users[].UserName"'

# Then use:
# iamgroups          # List all concert groups
# iamgroups-dev      # List users in developers group
# iamgroups-test     # List users in testers group

# ═══════════════════════════════════════════════════════════════════════════
# ACCOUNT INFORMATION
# ═══════════════════════════════════════════════════════════════════════════

# Account ID: 123456789012
# Region: Global (IAM is global service)
# Created: October 31, 2025

# Contact: Your AWS Administrator
# Last Updated: October 31, 2025
