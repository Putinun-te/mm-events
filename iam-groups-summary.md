# IAM Groups Summary

## concert-developers
**Purpose:** Development team with read access to infrastructure

**Policies:**
- ConcertS3FileStoragePolicy (custom)
- AmazonEC2ReadOnlyAccess
- CloudWatchFullAccess
- PowerUserAccess
- AmazonS3FullAccess

**Removed:** AWSLambda_FullAccess, AmazonAPIGatewayAdministrator (not used)

---

## concert-deployment
**Purpose:** Deployment team with full access to EC2, RDS, S3

**Policies:**
- ConcertS3FileStoragePolicy (custom)
- AmazonEC2FullAccess
- AmazonRDSFullAccess
- IAMReadOnlyAccess
- CloudWatchFullAccess
- PowerUserAccess
- AmazonS3FullAccess

**Removed:** AWSLambda_FullAccess (not used)

---

## concert-admins
**Purpose:** Full administrative access

**Policies:**
- ConcertS3FileStoragePolicy (custom)
- AdministratorAccess

**No changes needed**
