# AWS File Storage Implementation for Concert App

**Created:** October 30, 2025  
**Project:** Concert - Event & Booking Platform  
**Objective:** Implement S3 for file storage (event pictures, user avatars) with API Gateway and proper developer IAM access

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [AWS Services to Deploy](#aws-services-to-deploy)
3. [Implementation Steps](#implementation-steps)
4. [Developer IAM User Setup](#developer-iam-user-setup)
5. [Backend Integration](#backend-integration)
6. [Frontend Integration](#frontend-integration)
7. [API Gateway Configuration](#api-gateway-configuration)
8. [Security & Access Control](#security--access-control)

---

## Architecture Overview

### File Storage Architecture
```
User Frontend (Nuxt 4)
    ↓
API Gateway → S3 Pre-signed URLs
    ↓
Spring Boot Backend
    ↓
S3 Buckets (Pictures, Avatars)
    ↓
CloudFront CDN (Delivery)
```

### Service Components
| Component | Purpose | Details |
|-----------|---------|---------|
| **S3 Bucket (event-pictures)** | Store event images | Public read, private upload |
| **S3 Bucket (user-avatars)** | Store user avatars | Public read, private upload |
| **API Gateway** | REST endpoint for uploads | Pre-signed URL generation |
| **Lambda** | Generate pre-signed URLs | Secure upload token issuer |
| **IAM Roles** | Access control | Least privilege principle |
| **CloudFront** | CDN delivery | Cache & distribute files |

---

## AWS Services to Deploy

### 1. **S3 Buckets** (2x)
- `concert-event-pictures-dev` - Event images (500MB each event)
- `concert-user-avatars-dev` - User profile pictures (2MB max)

### 2. **API Gateway**
- REST API: `POST /upload` - Get pre-signed URL
- REST API: `GET /file/{filename}` - Retrieve file metadata
- Authentication: JWT tokens from backend

### 3. **Lambda Functions**
- `GeneratePresignedUrl` - Create S3 upload tokens
- `ValidateUploadToken` - Verify upload permissions

### 4. **CloudFront Distribution**
- Cache event pictures (24h TTL)
- Cache avatars (7d TTL)
- HTTPS only

### 5. **IAM Roles & Users**
- **Backend EC2 Role**: Read/write to S3, invoke Lambda
- **Developer User**: Full S3 access + API Gateway management
- **Frontend Role**: Read-only from S3

---

## Implementation Steps

### Step 1: Create S3 Buckets with Proper Configuration

**Bucket 1: Event Pictures**
```yaml
Bucket Name: concert-event-pictures-dev
Region: us-east-1
Versioning: Enabled
Encryption: AES-256
Block Public Access: True (initially)
Lifecycle Policy: Archive to Glacier after 1 year
```

**Bucket 2: User Avatars**
```yaml
Bucket Name: concert-user-avatars-dev
Region: us-east-1
Versioning: Disabled
Encryption: AES-256
Block Public Access: True (initially)
Lifecycle Policy: Delete after 5 years
```

### Step 2: Set Up IAM Users & Roles

**Developer User Creation**
```
Username: concert-developer
Access Type: Programmatic + Console
Permissions: Full S3, API Gateway, Lambda
MFA: Required
Policy: S3FullAccess + AmazonAPIGatewayFullAccess
```

**Backend EC2 Role**
```
Trust: EC2 Service
Permissions:
  - s3:PutObject (concert-event-pictures-dev/*)
  - s3:PutObject (concert-user-avatars-dev/*)
  - s3:GetObject (both buckets)
  - lambda:InvokeFunction (GeneratePresignedUrl)
```

### Step 3: Configure API Gateway

**Pre-signed URL Endpoint**
```
Method: POST
Path: /upload
Request: { userId, fileType, fileName }
Response: { uploadUrl, expiration }
Authorization: Bearer JWT
```

### Step 4: Create Lambda Function for Pre-signed URLs

**Function: GeneratePresignedUrl**
```python
import boto3
import json
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    
    bucket = 'concert-event-pictures-dev' if body['fileType'] == 'event' \
             else 'concert-user-avatars-dev'
    
    key = f"{body['userId']}/{body['fileName']}"
    
    url = s3_client.generate_presigned_post(
        Bucket=bucket,
        Key=key,
        ExpiresIn=3600,  # 1 hour
        Conditions=[
            ["content-length-range", 0, 52428800]  # 50MB max
        ]
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(url),
        'headers': {'Content-Type': 'application/json'}
    }
```

---

## Developer IAM User Setup

### Creating a Developer User in AWS Console

**Steps:**
1. Go to IAM → Users → Create User
2. Enter Username: `concert-developer`
3. Select: "Provide user access to AWS Management Console"
4. Create Custom Password
5. Uncheck: "User must create a new password on next sign-in"
6. Next → Attach Permissions

**Attach Policies:**
- `AmazonS3FullAccess`
- `AmazonAPIGatewayFullAccess`
- `AWSLambdaFullAccess`
- `CloudFrontFullAccess`
- Custom policy for least privilege:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3FileManagement",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::concert-event-pictures-dev",
        "arn:aws:s3:::concert-event-pictures-dev/*",
        "arn:aws:s3:::concert-user-avatars-dev",
        "arn:aws:s3:::concert-user-avatars-dev/*"
      ]
    },
    {
      "Sid": "APIGatewayManagement",
      "Effect": "Allow",
      "Action": [
        "apigateway:GET",
        "apigateway:POST",
        "apigateway:PUT",
        "apigateway:DELETE"
      ],
      "Resource": "arn:aws:apigateway:us-east-1::/restapis/*"
    }
  ]
}
```

**Generate Access Keys:**
1. Click on User → Security credentials
2. Create access key
3. Download CSV (save securely)
4. Enable MFA (authenticator app)

---

## Backend Integration

### Add AWS SDK to Spring Boot

**pom.xml additions:**
```xml
<!-- AWS SDK v2 -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.25.0</version>
</dependency>
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>apigatewaymanagementapi</artifactId>
    <version>2.25.0</version>
</dependency>
```

### Create S3 Service in Spring Boot

**File: `S3FileService.java`**
```java
package com.concert.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import java.time.Duration;

@Service
public class S3FileService {
    
    private final S3Client s3Client;
    private final S3Presigner s3Presigner;
    
    @Value("${aws.s3.bucket.pictures}")
    private String picturesBucket;
    
    @Value("${aws.s3.bucket.avatars}")
    private String avatarsBucket;
    
    @Value("${aws.s3.region}")
    private String region;
    
    public S3FileService(S3Client s3Client, S3Presigner s3Presigner) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
    }
    
    /**
     * Generate pre-signed URL for uploading event picture
     */
    public String generateEventPictureUploadUrl(String eventId, String fileName) {
        return generatePresignedUrl(picturesBucket, eventId + "/" + fileName, 3600);
    }
    
    /**
     * Generate pre-signed URL for uploading user avatar
     */
    public String generateAvatarUploadUrl(String userId, String fileName) {
        return generatePresignedUrl(avatarsBucket, userId + "/" + fileName, 3600);
    }
    
    /**
     * Common method to generate pre-signed URL
     */
    private String generatePresignedUrl(String bucket, String key, int expirationSeconds) {
        try {
            PutObjectRequest objectRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType("image/jpeg")
                .build();
            
            PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofSeconds(expirationSeconds))
                .putObjectRequest(objectRequest)
                .build();
            
            PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);
            return presignedRequest.url().toString();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate pre-signed URL: " + e.getMessage());
        }
    }
    
    /**
     * Delete file from S3
     */
    public void deleteFile(String bucket, String key) {
        try {
            s3Client.deleteObject(DeleteObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build());
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete file: " + e.getMessage());
        }
    }
    
    /**
     * Get file metadata
     */
    public Map<String, String> getFileMetadata(String bucket, String key) {
        try {
            HeadObjectResponse response = s3Client.headObject(HeadObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build());
            
            return Map.of(
                "size", String.valueOf(response.contentLength()),
                "lastModified", response.lastModified().toString(),
                "contentType", response.contentType()
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to get file metadata: " + e.getMessage());
        }
    }
}
```

### Create Upload Controller

**File: `FileUploadController.java`**
```java
package com.concert.controller;

import com.concert.dto.PresignedUrlRequest;
import com.concert.dto.PresignedUrlResponse;
import com.concert.service.S3FileService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/files")
public class FileUploadController {
    
    private final S3FileService s3FileService;
    
    public FileUploadController(S3FileService s3FileService) {
        this.s3FileService = s3FileService;
    }
    
    @PostMapping("/event-picture-upload-url")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<PresignedUrlResponse> getEventPictureUploadUrl(
            @RequestBody PresignedUrlRequest request) {
        String uploadUrl = s3FileService.generateEventPictureUploadUrl(
            request.getEventId(),
            request.getFileName()
        );
        return ResponseEntity.ok(new PresignedUrlResponse(uploadUrl, 3600));
    }
    
    @PostMapping("/avatar-upload-url")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<PresignedUrlResponse> getAvatarUploadUrl(
            @RequestBody PresignedUrlRequest request) {
        String uploadUrl = s3FileService.generateAvatarUploadUrl(
            request.getUserId(),
            request.getFileName()
        );
        return ResponseEntity.ok(new PresignedUrlResponse(uploadUrl, 3600));
    }
}
```

### Add to application.properties

```properties
# AWS S3 Configuration
aws.s3.region=us-east-1
aws.s3.bucket.pictures=concert-event-pictures-dev
aws.s3.bucket.avatars=concert-user-avatars-dev
aws.s3.signature-version=s3v4

# S3 Pre-signed URL expiration (seconds)
aws.s3.presigned-url-expiration=3600
```

---

## Frontend Integration

### Add Upload Component in Nuxt

**File: `FileUploadWidget.vue`**
```vue
<template>
  <div class="upload-widget">
    <input 
      type="file" 
      ref="fileInput" 
      @change="handleFileSelect"
      accept="image/*"
      class="file-input"
    />
    <button @click="openFilePicker" class="upload-btn">
      {{ label }}
    </button>
    <div v-if="uploading" class="progress">
      Uploading: {{ uploadProgress }}%
    </div>
    <div v-if="error" class="error">{{ error }}</div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  type: { // 'event-picture' or 'avatar'
    type: String,
    required: true
  },
  entityId: { // eventId or userId
    type: String,
    required: true
  },
  label: {
    type: String,
    default: 'Upload Image'
  }
})

const emit = defineEmits(['upload-success', 'upload-error'])

const fileInput = ref(null)
const uploading = ref(false)
const uploadProgress = ref(0)
const error = ref(null)

const openFilePicker = () => {
  fileInput.value.click()
}

const handleFileSelect = async (event) => {
  const file = event.target.files[0]
  if (!file) return
  
  try {
    error.value = null
    uploading.value = true
    
    // Step 1: Get pre-signed URL from backend
    const endpoint = props.type === 'avatar' 
      ? '/api/files/avatar-upload-url'
      : '/api/files/event-picture-upload-url'
    
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: props.type === 'avatar' ? props.entityId : undefined,
        eventId: props.type === 'event-picture' ? props.entityId : undefined,
        fileName: file.name
      })
    })
    
    const { uploadUrl } = await response.json()
    
    // Step 2: Upload to S3 using pre-signed URL
    await uploadToS3(file, uploadUrl)
    
    emit('upload-success', {
      fileName: file.name,
      fileSize: file.size,
      uploadUrl
    })
  } catch (err) {
    error.value = err.message
    emit('upload-error', err)
  } finally {
    uploading.value = false
  }
}

const uploadToS3 = (file, presignedUrl) => {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        uploadProgress.value = Math.round((e.loaded / e.total) * 100)
      }
    })
    
    xhr.addEventListener('load', () => {
      if (xhr.status === 200) {
        resolve()
      } else {
        reject(new Error(`Upload failed with status ${xhr.status}`))
      }
    })
    
    xhr.addEventListener('error', () => reject(new Error('Upload failed')))
    xhr.open('PUT', presignedUrl)
    xhr.setRequestHeader('Content-Type', file.type)
    xhr.send(file)
  })
}
</script>

<style scoped>
.upload-widget {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.file-input {
  display: none;
}

.upload-btn {
  padding: 0.5rem 1rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
}

.upload-btn:hover {
  background-color: #45a049;
}

.progress {
  padding: 0.5rem;
  background-color: #e8f5e9;
  border-radius: 4px;
  color: #2e7d32;
  font-weight: 600;
}

.error {
  padding: 0.5rem;
  background-color: #ffebee;
  border-radius: 4px;
  color: #c62828;
}
</style>
```

---

## API Gateway Configuration

### REST API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/upload/event-picture` | POST | Get pre-signed URL for event image |
| `/upload/avatar` | POST | Get pre-signed URL for avatar |
| `/files/{type}/{id}` | GET | Retrieve file list for entity |
| `/files/{fileId}` | DELETE | Delete uploaded file |

### API Gateway Integration with Lambda

```yaml
REST API: concert-file-upload
Resources:
  /upload
    /event-picture
      POST -> Lambda: GeneratePresignedUrl
    /avatar
      POST -> Lambda: GeneratePresignedUrl
  /files
    /{type}
      /{id}
        GET -> Lambda: ListFiles
        DELETE -> Lambda: DeleteFile
```

---

## Security & Access Control

### S3 Bucket Policies

**Event Pictures Bucket Policy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::concert-event-pictures-dev/*"
    },
    {
      "Sid": "BackendWrite",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/concert-backend-role"
      },
      "Action": ["s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::concert-event-pictures-dev/*"
    }
  ]
}
```

### CORS Configuration

**S3 CORS Settings**
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["https://concert-dev.example.com"],
    "ExposeHeaders": ["ETag", "x-amz-version-id"],
    "MaxAgeSeconds": 3000
  }
]
```

### CloudFront Security

- HTTPS only
- OAI (Origin Access Identity) for S3
- Custom headers for origin validation
- WAF rules for DDoS protection

---

## Implementation Checklist

- [ ] Create S3 buckets (event-pictures, user-avatars)
- [ ] Create IAM developer user with policies
- [ ] Generate developer access keys
- [ ] Set up API Gateway REST API
- [ ] Create Lambda function for pre-signed URLs
- [ ] Add AWS SDK to Spring Boot pom.xml
- [ ] Create S3FileService in backend
- [ ] Create FileUploadController endpoints
- [ ] Add configuration to application.properties
- [ ] Create FileUploadWidget component in Nuxt
- [ ] Configure CloudFront distribution
- [ ] Set up S3 bucket policies
- [ ] Configure CORS settings
- [ ] Test end-to-end file upload
- [ ] Set up monitoring & logging
- [ ] Document API endpoints for team

---

## Cost Estimation (Monthly)

| Service | Usage | Estimated Cost |
|---------|-------|-----------------|
| S3 Storage | 100GB | $2.30 |
| S3 Requests | 100K PUTs, 1M GETs | $5.50 |
| Data Transfer | 50GB/month | $4.50 |
| API Gateway | 1M requests | $3.50 |
| Lambda | 100K invocations | $0.20 |
| CloudFront | 50GB/month | $8.50 |
| **Total** | | **~$24.50/month** |

---

## Next Steps

1. **Create AWS resources** using AWS Console or Terraform
2. **Generate developer credentials** for team access
3. **Implement backend services** with S3 integration
4. **Build frontend components** for file upload
5. **Test end-to-end** file upload workflow
6. **Set up monitoring** for file operations

---

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS SDK for Java](https://docs.aws.amazon.com/sdk-for-java/)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/)
- [CloudFront with S3](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
