# IAM Team Groups Configuration Guide

**Date:** October 31, 2025  
**Project:** Concert Application  
**File:** `aws/iam_team_groups.tf`  
**Status:** Production Ready

## 📋 Overview

This document provides a comprehensive guide to the IAM user groups designed for the Concert application. The configuration implements role-based access control (RBAC) following the principle of least privilege.

## 🎯 Team Structure

The Concert application has four primary team types:

| Team | Group Name | Purpose | Environment |
|------|-----------|---------|-------------|
| **Developers** | `concert-developers` | Code development and local testing | Development |
| **Testers** | `concert-testers` | QA testing and test environment | Testing/Staging |
| **Deployment** | `concert-deployment` | CI/CD pipelines and deployments | All |
| **Admins** | `concert-admins` | Infrastructure and security management | All |

---

## 👨‍💻 DEVELOPERS GROUP

### Purpose
Enable developers to:
- Write and test code locally
- Access development AWS resources
- Manage their own credentials
- View application logs and metrics

### Permissions Granted

#### EC2 Access
- **Describe operations** (read-only for dev environment)
- View instances, security groups, networks, subnets, VPCs
- **Condition:** Only resources tagged with `Environment=dev`

#### S3 Bucket Access
- **Buckets:**
  - `concert-event-pictures-dev`
  - `concert-user-avatars-dev`
- **Operations:**
  - `ListBucket` - Browse bucket contents
  - `GetObject` - Download files
  - `PutObject` - Upload/update files
  - `DeleteObject` - Remove files
  - `GetObjectVersion` - Access file versions

#### RDS Database Access
- **Operations:**
  - `DescribeDBInstances` - View database instances
  - `DescribeDBClusters` - View database clusters
  - `ListTagsForResource` - See resource tags
- **Condition:** Only dev environments

#### Lambda Functions
- `InvokeFunction` - Execute Lambda functions
- `GetFunction` - View function details
- `ListFunctions` - List available functions
- **Scope:** Only `concert-*-dev` functions

#### CloudWatch Logs
- View Lambda and API Gateway logs
- Filter and search logs for debugging

#### Self-Service Credentials
- Create and manage own IAM access keys
- Change own password
- Setup and manage MFA devices
- View own user details

### Use Cases
✅ Developing new features  
✅ Debugging issues in dev environment  
✅ Testing code changes  
✅ Managing personal credentials  
✅ Monitoring their deployments  

### Denied Operations
❌ Create/delete EC2 instances  
❌ Modify RDS databases  
❌ Deploy to production  
❌ Access staging/test environments  
❌ Modify IAM policies or users  

---

## 🧪 TESTERS GROUP

### Purpose
Enable QA testers to:
- Execute and validate tests
- Access test and staging environments
- Create test data
- Generate test reports
- Review application logs

### Permissions Granted

#### EC2 Access
- **Read-only** access to test and staging environments
- Cannot modify instances or infrastructure
- **Condition:** Resources tagged with `Environment=test` or `Environment=staging`

#### S3 Test Buckets
- **Buckets:**
  - `concert-event-pictures-test`
  - `concert-user-avatars-test`
- **Full operations:**
  - List, get, put, delete objects
  - Manage test data

#### RDS Access
- Connect to test and staging databases
- View database information
- Execute test queries (via RDS client)
- **Condition:** Only test/staging environments

#### Lambda Testing
- Invoke test Lambda functions
- View function details
- Execute test scenarios

#### API Gateway Access
- Execute GET, HEAD, OPTIONS requests (read operations)
- Execute POST, PUT, DELETE requests (data manipulation)
- Test endpoints with various payloads

#### CloudWatch & Monitoring
- View CloudWatch metrics
- Describe alarms
- Review logs from test environments

#### Self-Service Credentials
- Manage own IAM credentials
- Change password
- Create/manage access keys

### Use Cases
✅ Running test suites  
✅ Creating test data  
✅ Verifying bug fixes  
✅ Load testing  
✅ API endpoint testing  
✅ Generating test reports  

### Denied Operations
❌ Access production environment  
❌ Modify infrastructure  
❌ Create EC2 instances  
❌ Change RDS configurations  
❌ Access developer credentials  

---

## 🚀 DEPLOYMENT GROUP

### Purpose
Enable DevOps engineers to:
- Execute CI/CD pipelines
- Deploy applications
- Manage infrastructure updates
- Monitor deployments

### Permissions Granted

#### EC2 Instance Management
- **Describe** instances and configurations
- **Control:** Start, stop, reboot instances
- **Tagging:** Create and delete tags for tracking
- **Scope:** All environments (dev, staging, prod)

#### ECS Task Management
- Describe tasks and services
- Update services (deploy new task definitions)
- Register new task definitions
- Run/stop tasks
- Manage ECS clusters

#### RDS Database Management
- Describe database instances and clusters
- Modify database configurations
- Create snapshots and restore from snapshots
- Manage tags for tracking

#### S3 Deployment Access
- Manage deployment artifacts in S3
- Handle versioning for rollback capability
- Access Terraform state files
- **Buckets:** All concert-* buckets in dev/staging/prod

#### Lambda Deployment
- Update function code and configuration
- Publish new versions
- Manage aliases for traffic shifting
- List available functions

#### API Gateway Management
- Deploy API changes
- Update stages (prod, staging, dev)
- Manage API gateway configuration

#### CloudFormation Stack Management
- View CloudFormation stacks
- Create, update, delete stacks
- Track stack events
- Validate templates

#### Terraform State Management
- Access S3 state files
- Use DynamoDB state locking (concurrent deployment prevention)
- Maintain Terraform configurations

#### CloudWatch Logs
- Create log groups
- Create log streams
- Write logs
- View deployment logs

#### IAM Pass Role
- Assume/pass roles to ECS tasks and Lambda functions
- **Limited to:** Service-specific roles (not admin roles)

### Use Cases
✅ Deploying code to production  
✅ Running CI/CD pipelines  
✅ Rolling out new features  
✅ Emergency deployments  
✅ Database migration tasks  
✅ Infrastructure scaling  

### Denied Operations
❌ Create/modify IAM users or policies  
❌ Access AWS billing information  
❌ Delete production databases  
❌ Modify security groups permanently  
❌ Access admin-only resources  

---

## 👑 ADMINS GROUP

### Purpose
Enable administrators to:
- Manage all AWS resources
- Handle security and compliance
- Manage team access and permissions
- Audit infrastructure

### Permissions Granted

#### Full AWS Access
- **AdministratorAccess** policy (AWS managed)
- Permits all AWS actions

#### IAM User Management
- Create/delete users
- Modify user configurations
- Add users to groups
- Remove users from groups
- View user details

#### IAM Group Management
- Create/delete groups
- Update group configurations
- Manage group memberships
- View group policies

#### IAM Policy Management
- Create/delete policies
- Manage policy versions
- Attach/detach policies
- View policy contents

#### IAM Role Management
- Create/delete roles
- Modify role trust relationships
- Attach/detach role policies
- Create service roles

#### Security Auditing
- Access CloudTrail logs
- View event history
- Describe trail configurations

#### VPC & Network Management
- Full EC2 and VPC permissions
- Manage security groups
- Configure network ACLs
- Setup VPN and peering

#### Billing & Cost Management
- View cost and usage data
- Create and manage budgets
- Access cost forecasts

#### Self-Service Credentials
- Manage own IAM credentials
- Change password
- Create/manage access keys

### Use Cases
✅ Onboarding new team members  
✅ Security incident response  
✅ Infrastructure audits  
✅ Policy and permission reviews  
✅ Cost optimization  
✅ Disaster recovery  
✅ Account-level changes  

### Permissions Scope
✅ All AWS services  
✅ All environments (dev, staging, prod)  
✅ All resources  

---

## 📊 Permission Matrix

| Permission | Developers | Testers | Deployment | Admins |
|------------|:----------:|:-------:|:----------:|:------:|
| Read Dev EC2 | ✅ | ❌ | ✅ | ✅ |
| Modify Dev EC2 | ❌ | ❌ | ✅ | ✅ |
| Read Test EC2 | ❌ | ✅ | ✅ | ✅ |
| Modify Test EC2 | ❌ | ❌ | ✅ | ✅ |
| Read Prod EC2 | ❌ | ❌ | ✅ | ✅ |
| Modify Prod EC2 | ❌ | ❌ | ✅ | ✅ |
| Deploy Lambda | ❌ | ❌ | ✅ | ✅ |
| Invoke Lambda | ✅ | ✅ | ✅ | ✅ |
| Manage S3 Dev | ✅ | ❌ | ✅ | ✅ |
| Manage S3 Test | ❌ | ✅ | ✅ | ✅ |
| Manage S3 Prod | ❌ | ❌ | ✅ | ✅ |
| Modify RDS | ❌ | ❌ | ✅ | ✅ |
| Manage IAM | ❌ | ❌ | ❌ | ✅ |
| View Billing | ❌ | ❌ | ❌ | ✅ |

---

## 🔧 Implementation Steps

### 1. Deploy IAM Groups

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan
```

### 2. Verify Group Creation

```bash
# List all groups
aws iam list-groups

# Check specific group members
aws iam get-group --group-name concert-developers
aws iam get-group --group-name concert-testers
aws iam get-group --group-name concert-deployment
aws iam get-group --group-name concert-admins

# View group policies
aws iam list-group-policies --group-name concert-developers
```

### 3. Add Users to Groups

```bash
# Add developer user
aws iam add-user-to-group \
  --group-name concert-developers \
  --user-name john.developer

# Add tester user
aws iam add-user-to-group \
  --group-name concert-testers \
  --user-name jane.tester

# Add deployment user
aws iam add-user-to-group \
  --group-name concert-deployment \
  --user-name alex.devops

# Add admin user
aws iam add-user-to-group \
  --group-name concert-admins \
  --user-name sarah.admin
```

### 4. Remove Users from Groups

```bash
aws iam remove-user-from-group \
  --group-name concert-developers \
  --user-name john.developer
```

---

## 🔐 Security Best Practices

### MFA Enforcement
All users should have MFA enabled:
```bash
# Create virtual MFA device
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name arn:aws:iam::ACCOUNT:mfa/john.developer \
  --outfile /secure/path/QRCode.png
```

### Access Key Rotation
Rotate access keys every 90 days:
```bash
# Create new access key
aws iam create-access-key --user-name john.developer

# List old keys
aws iam list-access-keys --user-name john.developer

# Delete old key
aws iam delete-access-key \
  --user-name john.developer \
  --access-key-id AKIAIOSFODNN7EXAMPLE
```

### Audit and Monitoring
Enable CloudTrail to monitor IAM actions:
```bash
# View recent IAM actions
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutUserPolicy
```

### Cross-Team Communication
Never share credentials:
- ❌ Share access keys in Slack/Email
- ❌ Store credentials in Git
- ✅ Use AWS SSO or temporary credentials
- ✅ Use AWS Systems Manager Session Manager for server access

---

## 📈 Scaling Considerations

### Adding New Teams
To add a new team (e.g., "Security"):

```hcl
resource "aws_iam_group" "security" {
  name        = "concert-security"
  path        = "/teams/"
  description = "Security team..."
}

resource "aws_iam_group_policy" "security_policy" {
  name   = "concert-security-policy"
  group  = aws_iam_group.security.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Define specific permissions
    ]
  })
}
```

### Multi-Account Setup
For multi-account architecture:

```hcl
# Add cross-account role assumption
{
  Sid    = "AssumeRoleInOtherAccounts"
  Effect = "Allow"
  Action = "sts:AssumeRole"
  Resource = "arn:aws:iam::OTHER_ACCOUNT:role/concert-*"
}
```

---

## 🆘 Troubleshooting

### User Cannot Access Resource
1. Verify user is in correct group
2. Check group policies are attached
3. Verify resource tags match conditions
4. Check for explicit Deny statements

### Permission Denied on Deployment
- Check if deployment user is in `concert-deployment` group
- Verify PassRole permission for service roles
- Check Terraform state file S3 bucket access

### Development User Cannot Access Dev EC2
- Verify EC2 instance has `Environment=dev` tag
- Check security group allows IAM user's IP
- Verify user has `ec2:DescribeInstances` permission

---

## 📞 Contact & Support

- **Access Issues:** Contact your AWS Account Administrator
- **Policy Questions:** Review this documentation or contact DevOps team
- **Onboarding New Users:** Contact security team at security@concert.local

---

## 📝 Change History

| Date | Change | Author |
|------|--------|--------|
| Oct 31, 2025 | Initial IAM team groups configuration | DevOps Team |

---

**Status:** ✅ Ready for Production  
**Last Updated:** October 31, 2025  
**Maintained By:** DevOps & Security Team
