# AWS File Storage & Developer Access Setup Guide

**Date:** October 30, 2025  
**Status:** Implementation Ready  
**Version:** 1.0

---

## Executive Summary

This document provides a complete setup guide for implementing AWS file storage for the Concert application with S3, API Gateway, and Lambda. It includes:

1. ✅ **AWS Infrastructure Code** (Terraform)
2. ✅ **Backend Integration** (Spring Boot)
3. ✅ **Frontend Components** (Nuxt 4)
4. ✅ **Developer IAM Access** (AWS Console)
5. ✅ **API Gateway Configuration** (Lambda)

---

## Files Created

### Terraform Configuration
```
aws/s3_file_storage.tf              - S3 buckets for pictures and avatars
aws/iam_developer_access.tf         - IAM roles, groups, and developer permissions
aws/api_gateway_lambda.tf           - API Gateway and Lambda configuration
aws/lambda/index.py                 - Lambda function for pre-signed URLs
```

### Backend Services
```
main_backend/src/main/java/com/concert/service/S3FileService.java
  → Service for S3 operations, pre-signed URLs, and metadata

main_backend/src/main/java/com/concert/controller/FileUploadController.java
  → REST endpoints for file upload requests

main_backend/src/main/java/com/concert/dto/PresignedUrlRequest.java
  → DTO for upload URL requests

main_backend/src/main/java/com/concert/dto/PresignedUrlResponse.java
  → DTO for upload URL responses
```

### Documentation
```
AWS_FILE_STORAGE_IMPLEMENTATION.md  - Complete implementation guide (this file)
AWS_DEVELOPER_SETUP_CHECKLIST.md    - Step-by-step setup checklist
```

---

## Architecture Overview

### Components
```
┌─────────────┐
│   Nuxt 4    │ (Frontend)
│  Component  │
└──────┬──────┘
       │ Request upload URL
       ↓
┌─────────────────────┐
│  Spring Boot        │
│  Backend API        │
│  /api/files/        │
└──────┬──────────────┘
       │ Get pre-signed URL
       ↓
┌─────────────────────┐
│   API Gateway       │
│   /upload/*         │
└──────┬──────────────┘
       │ Invoke Lambda
       ↓
┌─────────────────────┐
│  Lambda Function    │
│  GeneratePresigned  │
│  PresignedURL       │
└──────┬──────────────┘
       │ Return S3 URL
       ↓
┌─────────────────────┐
│   S3 Buckets        │
│  - event-pictures   │
│  - user-avatars     │
└─────────────────────┘
```

### Data Flow
1. **Frontend** → User selects file to upload
2. **Frontend** → Calls `/api/files/avatar-upload-url` with userId
3. **Backend** → Validates request
4. **Backend** → Calls API Gateway `/upload/avatar`
5. **API Gateway** → Invokes Lambda function
6. **Lambda** → Generates pre-signed URL
7. **Lambda** → Returns URL with 1-hour expiration
8. **Backend** → Returns URL to frontend
9. **Frontend** → Uses URL to upload file directly to S3
10. **S3** → Stores file with automatic public read access

---

## AWS Services Deployed

### S3 Buckets (2)
| Bucket | Purpose | Size Limit | Retention |
|--------|---------|-----------|-----------|
| concert-event-pictures-dev | Event images | 50MB each | 1 year (archive to Glacier) |
| concert-user-avatars-dev | User profiles | 5MB each | 5 years |

### API Gateway
- REST API: `concert-file-upload-api`
- Stage: `dev`
- Endpoints:
  - `POST /upload/event-picture` → Lambda
  - `POST /upload/avatar` → Lambda

### Lambda
- Function: `concert-generate-presigned-url`
- Runtime: Python 3.11
- Role: `concert-lambda-presigned-url-role`
- Timeout: 30 seconds (default)

### IAM Components
- **Backend EC2 Role**: S3 read/write permissions
- **Developer Group**: S3 + API Gateway + Lambda access
- **Instance Profile**: Attached to EC2 instances

### CloudWatch
- Log Groups:
  - `/aws/apigateway/concert-file-upload`
  - `/aws/lambda/concert-generate-presigned-url`
- Retention: 7 days

---

## Step-by-Step Setup

### Step 1: Deploy AWS Infrastructure

```bash
# Navigate to terraform directory
cd /Users/putinan/development/DevOps/develop/aws

# Plan deployment
terraform plan -out=tfplan-files

# Apply infrastructure
terraform apply tfplan-files

# Note output values:
# - event_pictures_bucket_name
# - user_avatars_bucket_name
# - api_gateway_endpoint
# - lambda_function_arn
```

### Step 2: Create Lambda Zip File

```bash
# Create lambda deployment package
cd aws/lambda
zip -r lambda_presigned_url.zip index.py

# Copy to terraform directory
cp lambda_presigned_url.zip ../
```

### Step 3: Add AWS SDK Dependencies to Backend

Update `main_backend/pom.xml`:

```xml
<!-- AWS SDK v2 -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.25.0</version>
</dependency>

<!-- AWS SDK v2 - S3 Presigner -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3-transfer-manager</artifactId>
    <version>2.25.0</version>
</dependency>

<!-- Lombok -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

### Step 4: Configure Backend Properties

Update `main_backend/src/main/resources/application.properties`:

```properties
# AWS Configuration
aws.s3.region=us-east-1
aws.s3.bucket.pictures=concert-event-pictures-dev
aws.s3.bucket.avatars=concert-user-avatars-dev
aws.s3.presigned-url-expiration=3600
aws.s3.signature-version=s3v4

# AWS SDK Configuration
software.amazon.awssdk.s3.use-path-style-access=false
```

For production (in `application-prod.properties`):
```properties
aws.s3.bucket.pictures=concert-event-pictures-prod
aws.s3.bucket.avatars=concert-user-avatars-prod
```

### Step 5: Add AWS Configuration Bean

Create `main_backend/src/main/java/com/concert/config/AwsConfig.java`:

```java
package com.concert.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class AwsConfig {

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
            .region(software.amazon.awssdk.regions.Region.US_EAST_1)
            .build();
    }

    @Bean
    public S3Presigner s3Presigner() {
        return S3Presigner.builder()
            .region(software.amazon.awssdk.regions.Region.US_EAST_1)
            .build();
    }
}
```

### Step 6: Create Developer IAM User

**Via AWS Console:**

1. Go to IAM → Users → Create User
2. Username: `concert-developer`
3. Select: "Provide user access to AWS Management Console"
4. Password: Create custom (save securely)
5. Attach Groups: Select `concert-developers` group
6. Review and Create

**Generate Access Keys:**

1. Click on new user → Security credentials
2. "Create access key"
3. Application running on EC2? → Yes
4. Download CSV (save to `.env.example`)
5. Enable MFA (recommended for production)

**Update `.env.example`:**
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=us-east-1
S3_EVENT_PICTURES_BUCKET=concert-event-pictures-dev
S3_USER_AVATARS_BUCKET=concert-user-avatars-dev
API_GATEWAY_ENDPOINT=https://...execute-api.us-east-1.amazonaws.com/dev
```

### Step 7: Test Backend Integration

```bash
# Build backend
cd main_backend
mvn clean package

# Run tests
mvn test

# Start backend
mvn spring-boot:run
```

Test endpoint:
```bash
# Get event picture upload URL
curl -X POST http://localhost:8080/api/files/event-picture-upload-url \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -d '{
    "eventId": "event-123",
    "fileName": "concert-photo.jpg"
  }'

# Response:
{
  "uploadUrl": "https://concert-event-pictures-dev.s3.us-east-1.amazonaws.com/...",
  "expirationSeconds": 3600
}
```

### Step 8: Implement Frontend Upload Component

Use the provided `FileUploadWidget.vue` component in your Nuxt app:

```vue
<template>
  <FileUploadWidget
    type="event-picture"
    entity-id="event-123"
    label="Upload Event Photo"
    @upload-success="handleUploadSuccess"
    @upload-error="handleUploadError"
  />
</template>

<script setup>
const handleUploadSuccess = (data) => {
  console.log('File uploaded:', data.fileName)
}

const handleUploadError = (error) => {
  console.error('Upload failed:', error)
}
</script>
```

---

## Security Configuration

### S3 Bucket Policies

✅ **Implemented in Terraform**
- Public read access to pictures and avatars
- Backend EC2 role: read/write access
- Server-side encryption (AES-256)
- Versioning enabled (pictures)

### CORS Configuration

✅ **Implemented in Terraform**
```json
{
  "AllowedOrigins": ["https://concert-dev.example.com", "http://localhost:3000"],
  "AllowedMethods": ["GET", "PUT", "POST"],
  "AllowedHeaders": ["*"]
}
```

### IAM Policies

✅ **Implemented in Terraform**
- Developer group: Limited to Concert resources
- Backend role: S3 + Lambda access
- Instance profile: Attached to EC2

### Pre-signed URL Security

✅ **Implemented in Lambda**
- 1-hour expiration (configurable)
- Content-type validation (images only)
- File size limits:
  - Event pictures: 50MB
  - Avatars: 5MB
- Unique object keys per entity

---

## Testing & Validation

### Unit Tests

Create `main_backend/src/test/java/com/concert/service/S3FileServiceTest.java`:

```java
@SpringBootTest
class S3FileServiceTest {
    
    @MockBean
    private S3Client s3Client;
    
    @MockBean
    private S3Presigner s3Presigner;
    
    @Autowired
    private S3FileService s3FileService;
    
    @Test
    void testGenerateEventPictureUploadUrl() {
        String url = s3FileService.generateEventPictureUploadUrl("event-1", "photo.jpg");
        assertNotNull(url);
        assertTrue(url.contains("event-1/photo.jpg"));
    }
}
```

### Integration Tests

Create `main_backend/src/test/java/com/concert/controller/FileUploadControllerTest.java`:

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class FileUploadControllerTest {
    
    @LocalServerPort
    private int port;
    
    @MockBean
    private S3FileService s3FileService;
    
    @Test
    void testGetEventPictureUploadUrl() throws Exception {
        // Mock the service
        when(s3FileService.generateEventPictureUploadUrl(any(), any()))
            .thenReturn("https://...");
        
        // Test endpoint
        RestTemplate restTemplate = new RestTemplate();
        HttpEntity<PresignedUrlRequest> request = new HttpEntity<>(
            new PresignedUrlRequest("event-1", null, "photo.jpg")
        );
        
        ResponseEntity<PresignedUrlResponse> response = restTemplate.postForEntity(
            "http://localhost:" + port + "/api/files/event-picture-upload-url",
            request,
            PresignedUrlResponse.class
        );
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody().getUploadUrl());
    }
}
```

### Manual Testing

```bash
# 1. Get JWT token
TOKEN=$(curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' | jq -r '.token')

# 2. Request upload URL
UPLOAD_URL=$(curl -X POST http://localhost:8080/api/files/avatar-upload-url \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId":"user-1","fileName":"avatar.jpg"}' | jq -r '.uploadUrl')

# 3. Upload file to S3
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --data-binary @avatar.jpg

# 4. Verify file exists in S3
aws s3 ls s3://concert-user-avatars-dev/users/user-1/
```

---

## Monitoring & Logging

### CloudWatch Logs

**API Gateway Logs:**
```bash
aws logs tail /aws/apigateway/concert-file-upload --follow
```

**Lambda Logs:**
```bash
aws logs tail /aws/lambda/concert-generate-presigned-url --follow
```

### CloudWatch Metrics

Monitor in AWS Console:
- **API Gateway**: Requests, latency, errors (4xx, 5xx)
- **Lambda**: Duration, invocations, errors, throttles
- **S3**: Request count, data transfer, storage

### CloudWatch Alarms (Optional)

```bash
# Create alarm for Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name concert-lambda-errors \
  --alarm-description "Alert on Lambda function errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

---

## Cost Analysis

### Monthly Estimates

| Service | Usage | Cost |
|---------|-------|------|
| S3 Storage | 100GB | $2.30 |
| S3 PUT Requests | 100,000 | $0.50 |
| S3 GET Requests | 1,000,000 | $0.40 |
| Data Transfer | 50GB | $4.50 |
| API Gateway | 1M requests | $3.50 |
| Lambda | 100K invocations | $0.20 |
| **Total** | | **~$11.40/month** |

### Cost Optimization

1. ✅ Use pre-signed URLs (direct S3 uploads)
2. ✅ S3 Intelligent-Tiering (auto archive)
3. ✅ CloudFront caching (optional, add $8/month)
4. ✅ S3 Select for queries
5. ✅ Request metrics only for troubleshooting

---

## Production Checklist

- [ ] Create separate production S3 buckets
- [ ] Create separate production IAM roles
- [ ] Enable S3 bucket encryption with KMS
- [ ] Enable MFA for developer users
- [ ] Set up AWS Budgets alert ($100/month)
- [ ] Configure CloudFront for CDN
- [ ] Enable S3 access logging
- [ ] Set up CloudWatch alarms
- [ ] Document runbook for incidents
- [ ] Set up backup/disaster recovery
- [ ] Enable versioning on production buckets
- [ ] Configure S3 Cross-Region Replication (optional)

---

## Troubleshooting

### Common Issues

**Issue: "Access Denied" when uploading**
```
Solution: Check IAM role permissions, ensure instance profile is attached
aws ec2 describe-instances --instance-ids i-xxx --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

**Issue: Pre-signed URL expires immediately**
```
Solution: Check server time sync, verify AWS SDK version
date  # Check system time
aws --version  # Verify AWS CLI version
```

**Issue: Lambda timeout**
```
Solution: Increase timeout (currently 30s), check CloudWatch logs
aws lambda update-function-configuration \
  --function-name concert-generate-presigned-url \
  --timeout 60
```

**Issue: CORS errors in browser**
```
Solution: Verify CORS configuration on S3 buckets
aws s3api get-bucket-cors --bucket concert-user-avatars-dev
```

---

## Next Steps

1. ✅ Review Terraform configurations
2. ✅ Deploy infrastructure
3. ✅ Create developer IAM user
4. ✅ Integrate Spring Boot services
5. ✅ Build Nuxt upload component
6. ✅ Test end-to-end workflow
7. ✅ Set up monitoring/logging
8. ✅ Document for team

---

## Support & References

### AWS Documentation
- [S3 Pre-signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)
- [API Gateway with Lambda](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

### Team Resources
- Infrastructure: See `AWS_FILE_STORAGE_IMPLEMENTATION.md`
- Backend: See `S3FileService.java` and `FileUploadController.java`
- Frontend: See `FileUploadWidget.vue` in Nuxt components

---

**Document Version:** 1.0  
**Last Updated:** October 30, 2025  
**Next Review:** December 1, 2025
