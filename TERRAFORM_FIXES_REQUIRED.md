# Terraform Syntax Fixes Required

**Status:** Documentation of required fixes  
**Date:** October 31, 2025  
**Version:** 1.0

---

## 🔧 FIXES TO APPLY

### 1. **messaging.tf** - Remove duplicate data source (Line 265)

**Current:**
```hcl
data "aws_caller_identity" "current" {}
```

**Action:** DELETE - This is already defined in iam_developer_access.tf at line 900

---

### 2. **variables.tf** - Add frontend_domain variable

**Status:** ✅ COMPLETED

Added to variables.tf:
```hcl
variable "frontend_domain" {
  description = "Frontend domain for CORS configuration"
  type        = string
  default     = "localhost:3000"
}
```

---

### 3. **dynamodb.tf** - Fix all 9 tables (Lines 11-12, 41-42, etc.)

**Issue:** Using non-existent attributes `read_capacity_units` and `write_capacity_units`

**Solution:** Use `provisioned_throughput` block instead:

```hcl
# WRONG (current):
resource "aws_dynamodb_table" "session_tokens" {
  name           = "concert-session-tokens-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity_units  = var.environment == "prod" ? null : 5  ❌
  write_capacity_units = var.environment == "prod" ? null : 5  ❌
  ...
}

# CORRECT:
resource "aws_dynamodb_table" "session_tokens" {
  name           = "concert-session-tokens-${var.environment}"
  billing_mode   = var.environment == "prod" ? "PAY_PER_REQUEST" : "PROVISIONED"
  
  dynamic "provisioned_throughput" {
    for_each = var.environment == "prod" ? [] : [1]
    content {
      read_capacity_units  = 5
      write_capacity_units = 5
    }
  }
  ...
}
```

**Apply to:** All 9 DynamoDB tables + global secondary indexes

---

### 4. **elasticache.tf** - Fix parameter group name (Line 63)

**Issue:** `name_prefix` is not supported

**Current:**
```hcl
resource "aws_elasticache_parameter_group" "concert" {
  family      = "redis7"
  name_prefix = "concert-"  ❌
  description = "Concert Redis parameters"
```

**Correct:**
```hcl
resource "aws_elasticache_parameter_group" "concert" {
  family      = "redis7"
  name        = "concert-redis-params-${var.environment}"
  description = "Concert Redis parameters"
```

---

### 5. **rds.tf** - Fix monitoring attributes

**Issue #1:** Line 52 - `monitor_interval` should be `monitoring_interval`
**Issue #2:** Line 59 - `enable_cloudwatch_logs_exports` should be `enabled_cloudwatch_logs_exports`
**Issue #3:** Lines 147-155 - `aws_db_snapshot_copy_retention` resource doesn't exist

**Fix:**
```hcl
# WRONG:
monitor_interval            = var.environment == "prod" ? 60 : 0  ❌
enable_cloudwatch_logs_exports = ["error", "general", "slowquery"]  ❌

# CORRECT:
monitoring_interval             = var.environment == "prod" ? 60 : 0
enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

# DELETE this entire resource block:
resource "aws_db_snapshot_copy_retention" "concert" {
  source_db_snapshot_identifier = aws_db_instance.concert.id
  retention_days                = 30

  tags = {
    Name = "concert-snapshot-copy-${var.environment}"
  }
}
```

---

### 6. **iam_developer_access.tf** - Remove unsupported attributes (Lines 76-78, 89-91, etc.)

**Issue:** `description` and `tags` are not supported on aws_iam_group

**Current:**
```hcl
resource "aws_iam_group" "developers" {
  name        = "${var.project_name}-developers"
  path        = "/teams/"
  description = "Developer team - Code development, local testing, and feature branches"  ❌
  
  tags = {  ❌
    Team        = "Development"
    Purpose     = "Application Development"
    Environment = "dev"
  }
}
```

**Correct:**
```hcl
resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
  path = "/teams/"
}
```

**Apply to:** All 4 IAM groups (developers, testers, deployment, admins)

---

### 7. **messaging.tf** - Fix SQS redrive policy (Line 112-115)

**Issue:** Incorrect argument structure

**Current:**
```hcl
resource "aws_sqs_queue_redrive_policy" "email_queue" {
  queue_url              = aws_sqs_queue.email_queue.id
  dead_letter_target_arn = aws_sqs_queue.email_queue_dlq.arn  ❌
  max_receive_count      = 3  ❌
}
```

**Correct:**
```hcl
resource "aws_sqs_queue_redrive_policy" "email_queue" {
  queue_url = aws_sqs_queue.email_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_queue_dlq.arn
    maxReceiveCount     = 3
  })
}
```

---

### 8. **messaging.tf** - Fix SQS long polling attribute (Line 155)

**Issue:** `receive_message_wait_time_seconds` should be `receive_wait_time_seconds`

**Current:**
```hcl
resource "aws_sqs_queue" "analytics_queue" {
  ...
  receive_message_wait_time_seconds = 20  ❌
  ...
}
```

**Correct:**
```hcl
resource "aws_sqs_queue" "analytics_queue" {
  ...
  receive_wait_time_seconds  = 20
  ...
}
```

---

### 9. **s3_file_storage.tf** - Fix lifecycle configuration (Line 167)

**Issue:** Lifecycle rule missing filter requirement

**Current:**
```hcl
rule {
  id     = "archive-old-pictures"
  status = "Enabled"
  
  noncurrent_version_expiration {
    noncurrent_days = 90
  }
  ...
}
```

**Correct:**
```hcl
rule {
  id     = "archive-old-pictures"
  status = "Enabled"
  
  filter {
    prefix = ""
  }
  
  noncurrent_version_expiration {
    noncurrent_days = 90
  }
  ...
}
```

---

## ✅ MANUAL FIXES COMPLETED

- ✅ Added `frontend_domain` variable to variables.tf

## ⏳ FIXES STILL NEEDED

- ⏳ messaging.tf - Remove duplicate data source
- ⏳ dynamodb.tf - Rewrite all 9 tables with correct syntax
- ⏳ elasticache.tf - Fix parameter group configuration
- ⏳ rds.tf - Fix 3 attribute issues
- ⏳ iam_developer_access.tf - Remove 4 unsupported attributes
- ⏳ messaging.tf - Fix SQS redrive policy
- ⏳ messaging.tf - Fix SQS long polling
- ⏳ s3_file_storage.tf - Add filter to lifecycle rules

---

## 📋 VALIDATION COMMANDS

```bash
cd aws/
terraform validate          # Verify syntax
terraform init              # Initialize (don't commit .terraform/)
terraform plan -out=tfplan  # Review changes
terraform apply tfplan      # Deploy
```

---

## 🚀 DEPLOYMENT AFTER FIXES

After all fixes are applied:

```bash
cd aws/
terraform validate         # Should show: Success! The configuration is valid.
terraform plan
terraform apply tfplan
```

All infrastructure will be deployed successfully.

---

**Created:** October 31, 2025  
**Purpose:** Terraform syntax validation and repair  
**Status:** Reference guide for required fixes
