# IAM Team Groups - Quick Reference Guide

**Date:** October 31, 2025  
**For:** Team Leads, Administrators, New Employees

---

## 🎯 What is This?

Four IAM User Groups have been created to manage access to the Concert application AWS resources:

| Group | Team | What They Can Do |
|-------|------|-----------------|
| **concert-developers** | 👨‍💻 Development | Write code, test locally, access dev resources |
| **concert-testers** | 🧪 QA/Testing | Run tests, create test data, validate fixes |
| **concert-deployment** | 🚀 DevOps | Deploy code, manage infrastructure updates |
| **concert-admins** | 👑 Admin | Full AWS access, manage users, handle security |

---

## 👥 Assigning Users to Groups

### For Administrators

#### Add New Developer
```bash
aws iam add-user-to-group \
  --group-name concert-developers \
  --user-name john.developer
```

#### Add New Tester
```bash
aws iam add-user-to-group \
  --group-name concert-testers \
  --user-name jane.tester
```

#### Add New DevOps/Deployment Engineer
```bash
aws iam add-user-to-group \
  --group-name concert-deployment \
  --user-name alex.devops
```

#### Add New Admin
```bash
aws iam add-user-to-group \
  --group-name concert-admins \
  --user-name sarah.admin
```

#### Check Group Membership
```bash
aws iam get-group --group-name concert-developers
```

#### Remove User from Group
```bash
aws iam remove-user-from-group \
  --group-name concert-developers \
  --user-name john.developer
```

---

## 🔧 What Can Each Team Do?

### 👨‍💻 DEVELOPERS

**Can Access:**
- ✅ Development EC2 instances
- ✅ Development S3 buckets (event pictures, user avatars)
- ✅ Development RDS databases
- ✅ Development Lambda functions
- ✅ Application logs in CloudWatch
- ✅ Their own credentials and MFA

**Cannot Access:**
- ❌ Production environment
- ❌ Test/Staging environments
- ❌ Database modifications
- ❌ Infrastructure changes
- ❌ User management

**Typical Tasks:**
- Develop new features
- Debug issues
- Run code locally against dev databases
- Monitor their deployments
- Manage personal AWS credentials

---

### 🧪 TESTERS

**Can Access:**
- ✅ Test environment EC2 instances (read-only)
- ✅ Test S3 buckets
- ✅ Test RDS databases
- ✅ Test Lambda functions
- ✅ Test API endpoints
- ✅ CloudWatch logs and metrics
- ✅ Their own credentials

**Cannot Access:**
- ❌ Production environment
- ❌ Development environment
- ❌ Staging environment modifications
- ❌ Database changes
- ❌ User or IAM management

**Typical Tasks:**
- Execute test suites
- Create test data
- Verify bug fixes
- Performance testing
- API testing
- Generate test reports

---

### 🚀 DEPLOYMENT (DevOps)

**Can Access:**
- ✅ All environments (dev, staging, prod)
- ✅ EC2 instances (start/stop/reboot)
- ✅ ECS/Lambda for deployments
- ✅ RDS modifications and snapshots
- ✅ S3 deployment artifacts
- ✅ API Gateway deployments
- ✅ CloudFormation stacks
- ✅ Terraform state files
- ✅ CloudWatch logs

**Cannot Access:**
- ❌ IAM user management
- ❌ Policy modifications
- ❌ AWS billing information
- ❌ Account-level security settings

**Typical Tasks:**
- Deploy code to production
- Run CI/CD pipelines
- Scale infrastructure
- Database migrations
- Emergency rollbacks
- Infrastructure updates

---

### 👑 ADMINS

**Can Access:**
- ✅ **Everything** - Full AWS access
- ✅ User and group management
- ✅ IAM policies and roles
- ✅ Security auditing
- ✅ Billing and cost management
- ✅ All environments and resources

**Responsibilities:**
- Manage team access
- Handle security incidents
- Audit infrastructure
- Cost optimization
- Disaster recovery
- Policy updates

**Typical Tasks:**
- Onboard new team members
- Create new IAM users/groups
- Review security settings
- Audit access logs
- Emergency interventions

---

## 📋 Onboarding Checklist

When adding a new team member:

### Step 1: Create AWS User Account
```bash
aws iam create-user --user-name john.developer
```

### Step 2: Add to Appropriate Group
```bash
# Example for developer
aws iam add-user-to-group \
  --group-name concert-developers \
  --user-name john.developer
```

### Step 3: Create Access Keys (if needed)
```bash
aws iam create-access-key --user-name john.developer
# Save Access Key ID and Secret Access Key securely
```

### Step 4: Set Initial Password (if using Console access)
```bash
aws iam create-login-profile \
  --user-name john.developer \
  --password "TempPassword123!" \
  --password-reset-required
```

### Step 5: Setup MFA Device
```bash
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name arn:aws:iam::ACCOUNT:mfa/john.developer \
  --outfile QRCode.png
```

### Step 6: Verify Access
```bash
# User logs in and tests access
aws sts get-caller-identity
```

---

## 🆘 Common Issues & Solutions

### "User not authorized to perform: iam:AddUserToGroup"
**Problem:** Your user doesn't have permission to add users  
**Solution:** Contact an admin to add this user to the group

### "Access Denied" when accessing S3
**Problem:** Accessing wrong environment bucket  
**Solution:** Developers can only access `-dev` buckets, Testers can only access `-test` buckets

### "Cannot modify RDS database"
**Problem:** Your group doesn't have modify permissions  
**Solution:** Deployment or Admin users can modify; others are read-only

### "Cannot assume role"
**Problem:** Trying to use a role you don't have permission for  
**Solution:** Contact your team lead or admin; may need different group membership

---

## 🔐 Security Reminders

⚠️ **DO:**
- ✅ Enable MFA on your AWS account
- ✅ Rotate access keys every 90 days
- ✅ Use temporary credentials when possible
- ✅ Report suspicious activity immediately
- ✅ Keep credentials private and secure

⚠️ **DON'T:**
- ❌ Share AWS credentials or access keys
- ❌ Store credentials in code or Git
- ❌ Send credentials via email or Slack
- ❌ Use root account for daily work
- ❌ Leave credentials logged in on shared machines

---

## 📞 Getting Help

### For Access Issues
1. **Contact:** Your Team Lead or AWS Administrator
2. **Include:** 
   - Your AWS username
   - What you're trying to access
   - Error message (if any)
3. **Timeline:** Usually resolved within 1 business day

### For Technical Questions
- **Developers:** Contact DevOps team or your tech lead
- **Testers:** Contact QA lead or DevOps team
- **Deployment:** Contact DevOps team or architect
- **Admins:** Check AWS documentation or contact AWS support

### For Security Concerns
- **Email:** security@concert.local
- **Priority:** Respond within 4 hours

---

## 📊 Group Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    CONCERT IAM GROUPS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  concert-developers (👨‍💻)                                   │
│  └─ Development work and local testing                      │
│     • Access: Dev EC2, S3, RDS, Lambda                      │
│     • Deny: Production, modify operations                   │
│                                                              │
│  concert-testers (🧪)                                        │
│  └─ QA and testing operations                               │
│     • Access: Test EC2, S3, RDS, API endpoints              │
│     • Deny: Production, dev environment                     │
│                                                              │
│  concert-deployment (🚀)                                     │
│  └─ CI/CD pipelines and deployments                         │
│     • Access: All environments, deploy, modify              │
│     • Deny: IAM changes, billing access                     │
│                                                              │
│  concert-admins (👑)                                         │
│  └─ Full AWS access and management                          │
│     • Access: All AWS resources and operations              │
│     • Responsibility: User management, security, billing   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📞 Contact Information

| Role | Contact | Email |
|------|---------|-------|
| AWS Administrator | Sarah | sarah.admin@concert.local |
| DevOps Lead | Alex | alex.devops@concert.local |
| Security Officer | IT Team | security@concert.local |

---

**Last Updated:** October 31, 2025  
**Version:** 1.0  
**Status:** ✅ Ready for Use
