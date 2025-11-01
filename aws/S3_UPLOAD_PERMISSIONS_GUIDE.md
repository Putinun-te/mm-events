# 📦 S3 Upload Permissions Configuration

## ✅ Overview

Enhanced S3 permissions across all IAM groups and the backend EC2 role to support comprehensive file upload capabilities including multipart uploads, ACL management, and bucket policies.

---

## 🎯 Enhanced S3 Permissions

### Core Upload Permissions Added:

1. **`s3:PutObject`** - Upload objects (already existed)
2. **`s3:PutObjectAcl`** - Set object ACLs (NEW)
3. **`s3:GetObjectAcl`** - Read object ACLs (NEW)
4. **`s3:AbortMultipartUpload`** - Cancel multipart uploads (NEW)
5. **`s3:ListMultipartUploadParts`** - List parts of multipart upload (NEW)
6. **`s3:ListBucketMultipartUploads`** - List all multipart uploads (NEW)

### Deployment Group Additional Permissions:

7. **`s3:PutBucketAcl`** - Set bucket ACLs
8. **`s3:GetBucketAcl`** - Read bucket ACLs
9. **`s3:PutBucketPolicy`** - Update bucket policies
10. **`s3:GetBucketPolicy`** - Read bucket policies
11. **`s3:DeleteBucketPolicy`** - Delete bucket policies

---

## 👥 Permissions by Group

### 1. Backend EC2 Role (`concert-backend-ec2-role`)

**Purpose**: Application runtime file uploads

**Permissions**:
```json
{
  "S3ObjectAccess": [
    "s3:GetObject",
    "s3:PutObject",          // ✅ Upload files
    "s3:DeleteObject",
    "s3:GetObjectVersion",
    "s3:PutObjectAcl",       // ✅ Set file permissions
    "s3:GetObjectAcl",       // ✅ Read file permissions
    "s3:AbortMultipartUpload",    // ✅ Cancel large uploads
    "s3:ListMultipartUploadParts" // ✅ Track upload progress
  ],
  "S3MultipartUpload": [
    "s3:ListBucketMultipartUploads" // ✅ List ongoing uploads
  ]
}
```

**Buckets**:
- `concert-event-pictures-useast1-123456789012`
- `concert-user-avatars-useast1-123456789012`

**Use Cases**:
- Upload event images via Spring Boot API
- Upload user profile pictures
- Handle large file uploads (>5MB) with multipart
- Manage file permissions (public/private)
- Clean up failed uploads

---

### 2. Developer Group (`concert-developers`)

**Purpose**: Development and testing

**Permissions**:
```json
{
  "S3DevelopmentBucketAccess": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",          // ✅ Upload files
    "s3:DeleteObject",
    "s3:GetObjectVersion",
    "s3:PutObjectAcl",       // ✅ Set file permissions
    "s3:GetObjectAcl",       // ✅ Read file permissions
    "s3:AbortMultipartUpload",    // ✅ Cancel uploads
    "s3:ListMultipartUploadParts", // ✅ Track progress
    "s3:ListBucketMultipartUploads" // ✅ List uploads
  ]
}
```

**Buckets**: Same as backend EC2 role

**Use Cases**:
- Test file upload functionality
- Upload test images for development
- Debug upload issues
- Manage test data

---

### 3. Tester Group (`concert-testers`)

**Purpose**: QA testing

**Permissions**:
```json
{
  "S3TestBucketAccess": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",          // ✅ Upload test files
    "s3:DeleteObject",
    "s3:PutObjectAcl",       // ✅ Set permissions
    "s3:GetObjectAcl",       // ✅ Read permissions
    "s3:AbortMultipartUpload",
    "s3:ListMultipartUploadParts",
    "s3:ListBucketMultipartUploads"
  ]
}
```

**Buckets** (test environment):
- `concert-event-pictures-useast1-123456789012-test/*`
- `concert-user-avatars-useast1-123456789012-test/*`

**Use Cases**:
- Upload test images
- Test multipart upload scenarios
- Validate file permissions
- Test upload failure handling

---

### 4. Deployment Group (`concert-deployment`)

**Purpose**: Infrastructure management

**Permissions**:
```json
{
  "S3DeploymentAccess": [
    "s3:GetObject",
    "s3:PutObject",          // ✅ Upload files
    "s3:DeleteObject",
    "s3:ListBucket",
    "s3:GetBucketVersioning",
    "s3:GetObjectVersion",
    "s3:PutBucketVersioning",
    "s3:PutObjectAcl",       // ✅ Manage object ACLs
    "s3:GetObjectAcl",
    "s3:PutBucketAcl",       // ✅ Manage bucket ACLs
    "s3:GetBucketAcl",
    "s3:AbortMultipartUpload",
    "s3:ListMultipartUploadParts",
    "s3:ListBucketMultipartUploads",
    "s3:PutBucketPolicy",    // ✅ Manage bucket policies
    "s3:GetBucketPolicy",
    "s3:DeleteBucketPolicy"
  ],
  "TerraformStateAccess": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",          // ✅ Upload Terraform state
    "s3:DeleteObject",
    "s3:GetObjectVersion",
    "s3:ListBucketMultipartUploads",
    "s3:AbortMultipartUpload"
  ]
}
```

**Buckets**:
- All project buckets (`concert-*-dev`, `concert-*-test`, `concert-*-staging`)
- Terraform state bucket

**Use Cases**:
- Deploy static assets
- Manage bucket configurations
- Upload Terraform state files
- Configure CORS and bucket policies
- Manage large deployments

---

## 🔧 Implementation Examples

### 1. Simple File Upload (Spring Boot)

```java
@Service
public class S3Service {
    
    @Autowired
    private AmazonS3 s3Client;
    
    public String uploadFile(MultipartFile file, String bucketName) {
        String fileName = UUID.randomUUID() + "-" + file.getOriginalFilename();
        
        try {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentType(file.getContentType());
            metadata.setContentLength(file.getSize());
            
            s3Client.putObject(
                bucketName,
                fileName,
                file.getInputStream(),
                metadata
            );
            
            return s3Client.getUrl(bucketName, fileName).toString();
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload file", e);
        }
    }
}
```

### 2. Multipart Upload (Large Files >5MB)

```java
public String uploadLargeFile(File file, String bucketName) {
    TransferManager transferManager = TransferManagerBuilder
        .standard()
        .withS3Client(s3Client)
        .build();
    
    try {
        Upload upload = transferManager.upload(bucketName, file.getName(), file);
        upload.waitForCompletion();
        
        return s3Client.getUrl(bucketName, file.getName()).toString();
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        throw new RuntimeException("Upload interrupted", e);
    } finally {
        transferManager.shutdownNow();
    }
}
```

### 3. Upload with ACL (Public/Private)

```java
public String uploadWithAcl(MultipartFile file, String bucketName, boolean isPublic) {
    String fileName = UUID.randomUUID() + "-" + file.getOriginalFilename();
    
    try {
        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentType(file.getContentType());
        metadata.setContentLength(file.getSize());
        
        PutObjectRequest request = new PutObjectRequest(
            bucketName,
            fileName,
            file.getInputStream(),
            metadata
        );
        
        if (isPublic) {
            request.setCannedAcl(CannedAccessControlList.PublicRead);
        } else {
            request.setCannedAcl(CannedAccessControlList.Private);
        }
        
        s3Client.putObject(request);
        
        return s3Client.getUrl(bucketName, fileName).toString();
    } catch (IOException e) {
        throw new RuntimeException("Failed to upload file", e);
    }
}
```

### 4. Abort Failed Multipart Uploads (Cleanup)

```java
public void cleanupFailedUploads(String bucketName) {
    ListMultipartUploadsRequest listRequest = new ListMultipartUploadsRequest(bucketName);
    MultipartUploadListing uploadListing = s3Client.listMultipartUploads(listRequest);
    
    for (MultipartUpload upload : uploadListing.getMultipartUploads()) {
        // Abort uploads older than 24 hours
        if (upload.getInitiated().before(new Date(System.currentTimeMillis() - 86400000))) {
            s3Client.abortMultipartUpload(
                new AbortMultipartUploadRequest(
                    bucketName,
                    upload.getKey(),
                    upload.getUploadId()
                )
            );
        }
    }
}
```

### 5. AWS CLI Upload Examples

```bash
# Simple upload
aws s3 cp myfile.jpg s3://concert-event-pictures-useast1-123456789012/events/

# Upload with public-read ACL
aws s3 cp myfile.jpg s3://concert-event-pictures-useast1-123456789012/events/ \
  --acl public-read

# Upload large file (automatic multipart)
aws s3 cp largefile.mp4 s3://concert-event-pictures-useast1-123456789012/videos/

# Upload with metadata
aws s3 cp myfile.jpg s3://concert-event-pictures-useast1-123456789012/events/ \
  --metadata "title=Concert Photo,event=Rock Festival"

# List multipart uploads
aws s3api list-multipart-uploads \
  --bucket concert-event-pictures-useast1-123456789012

# Abort a specific multipart upload
aws s3api abort-multipart-upload \
  --bucket concert-event-pictures-useast1-123456789012 \
  --key events/myfile.jpg \
  --upload-id UPLOAD_ID
```

---

## 🎯 Common Upload Scenarios

### Scenario 1: Event Image Upload
```
User uploads event poster (3MB) → 
Spring Boot API receives MultipartFile → 
S3Service.uploadFile() → 
s3:PutObject permission used → 
File stored in s3://concert-event-pictures/events/uuid-poster.jpg
```

### Scenario 2: User Avatar Upload
```
User uploads profile picture (500KB) → 
API validates image → 
Resize image → 
Upload with public-read ACL → 
s3:PutObject + s3:PutObjectAcl → 
Publicly accessible avatar URL returned
```

### Scenario 3: Large Video Upload
```
Upload video (50MB) → 
TransferManager initiates multipart upload → 
s3:ListMultipartUploadParts tracks progress → 
Upload completes → 
s3:PutObject finalizes → 
Video available for streaming
```

### Scenario 4: Failed Upload Cleanup
```
Cron job runs daily → 
s3:ListBucketMultipartUploads lists incomplete uploads → 
Filter uploads > 24 hours old → 
s3:AbortMultipartUpload cleans up → 
Storage costs reduced
```

---

## 🔐 Security Considerations

### 1. ACL Management
- ✅ **Private by default**: All uploads are private unless explicitly set to public
- ✅ **Granular control**: Developers can set object-level ACLs
- ✅ **Deployment control**: Only deployment group can set bucket-level ACLs

### 2. Multipart Upload Limits
- Files > 5MB should use multipart upload
- Each part: 5MB to 5GB
- Maximum 10,000 parts per upload
- Clean up incomplete uploads to avoid storage charges

### 3. Content Type Validation
```java
private static final Set<String> ALLOWED_TYPES = Set.of(
    "image/jpeg", "image/png", "image/gif", "image/webp"
);

public void validateContentType(String contentType) {
    if (!ALLOWED_TYPES.contains(contentType)) {
        throw new IllegalArgumentException("Invalid content type");
    }
}
```

### 4. File Size Limits
```java
private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

public void validateFileSize(MultipartFile file) {
    if (file.getSize() > MAX_FILE_SIZE) {
        throw new IllegalArgumentException("File too large");
    }
}
```

---

## 📊 Permission Comparison

| Permission | Backend EC2 | Developers | Testers | Deployment |
|-----------|-------------|-----------|---------|------------|
| **Basic Upload** | ✅ | ✅ | ✅ | ✅ |
| **Multipart Upload** | ✅ | ✅ | ✅ | ✅ |
| **Set Object ACL** | ✅ | ✅ | ✅ | ✅ |
| **Set Bucket ACL** | ❌ | ❌ | ❌ | ✅ |
| **Bucket Policy** | ❌ | ❌ | ❌ | ✅ |
| **List Uploads** | ✅ | ✅ | ✅ | ✅ |
| **Abort Uploads** | ✅ | ✅ | ✅ | ✅ |
| **Version Control** | ✅ | ✅ | ❌ | ✅ |

---

## 🚀 Deployment

### Step 1: Validate Configuration
```bash
cd /Users/putinan/development/DevOps/develop/aws
terraform validate
```

### Step 2: Review Changes
```bash
terraform plan | grep -A 10 "s3:"
```

### Step 3: Apply Changes
```bash
terraform apply
```

### Step 4: Verify Permissions
```bash
# Test upload as developer
aws s3 cp test.jpg s3://concert-event-pictures-useast1-123456789012/test/

# Test multipart upload
aws s3 cp largefile.zip s3://concert-event-pictures-useast1-123456789012/test/

# Test ACL setting
aws s3api put-object-acl \
  --bucket concert-event-pictures-useast1-123456789012 \
  --key test/test.jpg \
  --acl public-read

# List multipart uploads
aws s3api list-multipart-uploads \
  --bucket concert-event-pictures-useast1-123456789012
```

---

## 📈 Monitoring Upload Activity

### CloudWatch Metrics
- `NumberOfObjects` - Total objects in bucket
- `BucketSizeBytes` - Total bucket size
- `AllRequests` - Total S3 requests
- `PutRequests` - Upload requests
- `4xxErrors` - Permission errors
- `5xxErrors` - Server errors

### CloudWatch Log Insights Query
```sql
fields @timestamp, @message
| filter @message like /PutObject/
| stats count() by bin(5m)
```

---

## 🧹 Maintenance

### Clean Up Incomplete Uploads
```bash
# List incomplete uploads
aws s3api list-multipart-uploads \
  --bucket concert-event-pictures-useast1-123456789012

# Abort all incomplete uploads (use with caution!)
aws s3api list-multipart-uploads \
  --bucket concert-event-pictures-useast1-123456789012 \
  --query 'Uploads[].{Key:Key,UploadId:UploadId}' \
  --output text | while read key uploadId; do
    aws s3api abort-multipart-upload \
      --bucket concert-event-pictures-useast1-123456789012 \
      --key "$key" \
      --upload-id "$uploadId"
done
```

### Create S3 Lifecycle Policy
```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket concert-event-pictures-useast1-123456789012 \
  --lifecycle-configuration file://lifecycle.json
```

**lifecycle.json**:
```json
{
  "Rules": [{
    "Id": "AbortIncompleteMultipartUpload",
    "Status": "Enabled",
    "AbortIncompleteMultipartUpload": {
      "DaysAfterInitiation": 1
    }
  }]
}
```

---

## ✅ Summary

### What Changed:
- ✅ Added multipart upload support to all groups
- ✅ Added ACL management permissions
- ✅ Enhanced deployment group with bucket policy management
- ✅ Added ability to clean up failed uploads
- ✅ Improved Terraform state management

### Benefits:
- 📈 **Large file support**: Multipart uploads for files >5MB
- 🔒 **Fine-grained control**: Object-level ACLs
- 💰 **Cost optimization**: Clean up incomplete uploads
- 🚀 **Better reliability**: Resume failed uploads
- 🛡️ **Enhanced security**: Granular permission management

### Next Steps:
1. Deploy IAM changes with `terraform apply`
2. Test upload functionality
3. Implement upload cleanup job
4. Set up S3 lifecycle policies
5. Monitor upload metrics in CloudWatch

**Status**: ✅ Ready for deployment
**Impact**: Enhanced S3 upload capabilities across all user groups
**Cost**: $0 (IAM is free)
