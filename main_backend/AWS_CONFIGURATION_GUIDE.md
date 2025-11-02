# AWS Infrastructure Configuration Guide

## Overview
This application uses AWS S3 for storing event pictures with centralized configuration.

## Configuration Properties

### Environment Variables (Production)
Set these environment variables before running the application:

```bash
# Required
export AWS_REGION=us-east-1
export AWS_S3_EVENT_PICTURES_BUCKET=your-production-bucket

# Optional (defaults shown)
export AWS_S3_PRESIGNED_URLS_ENABLED=true
export AWS_S3_PRESIGNED_URL_EXPIRATION_MINUTES=60
export AWS_S3_PUBLIC_ACCESS=false
```

### Security Best Practices

#### 1. IAM Role (Recommended)
Use IAM roles for EC2/ECS/Lambda with minimal permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-production-bucket/events/*"
    }
  ]
}
```

#### 2. S3 Bucket Configuration

**Bucket Policy (Private Bucket with Presigned URLs)**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-production-bucket/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Enable Encryption**:
- Go to S3 Console → Your Bucket → Properties → Default encryption
- Select "AES-256" or "AWS-KMS"

**Enable Versioning** (recommended):
- S3 Console → Your Bucket → Properties → Versioning → Enable

**Lifecycle Policy** (cleanup old files):
```json
{
  "Rules": [
    {
      "Id": "DeleteOldEventPictures",
      "Status": "Enabled",
      "Prefix": "events/",
      "Expiration": {
        "Days": 365
      },
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 30
      }
    }
  ]
}
```

**CORS Configuration**:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": [
      "http://localhost:3000",
      "https://your-production-frontend.com"
    ],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

## Configuration Modes

### Development (Local)
```properties
aws.region=us-east-1
aws.s3.event-pictures-bucket=concert-dev-bucket
aws.s3.presigned-urls-enabled=false
aws.s3.public-access=true
```

### Production (Secure)
```properties
aws.region=us-east-1
aws.s3.event-pictures-bucket=concert-prod-bucket
aws.s3.presigned-urls-enabled=true
aws.s3.presigned-url-expiration-minutes=60
aws.s3.public-access=false
```

## CloudFront Integration (Optional)

For better performance and lower costs:

1. Create CloudFront distribution pointing to your S3 bucket
2. Update `EventService` to use CloudFront URL instead of S3 direct URL
3. Configure CloudFront with:
   - Origin Access Identity (OAI) for S3
   - HTTPS only
   - Cache settings for images (1 day+)

## Monitoring

Enable S3 access logging:
```bash
aws s3api put-bucket-logging \
  --bucket your-production-bucket \
  --bucket-logging-status file://logging.json
```

logging.json:
```json
{
  "LoggingEnabled": {
    "TargetBucket": "your-logs-bucket",
    "TargetPrefix": "s3-access-logs/"
  }
}
```

## Cost Optimization

1. **Use Lifecycle Policies**: Delete old/unused files
2. **Enable CloudFront**: Reduce S3 data transfer costs
3. **Use Standard-IA**: For files accessed less frequently
4. **Monitor with AWS Cost Explorer**: Track S3 costs

## Testing

Tests use mock S3 clients - no AWS credentials required:
```bash
mvn test
```

Docker tests use isolated test bucket configuration:
```bash
mvn -Dtest='*DockerTest' test
```
