# AWS API Gateway Setup Guide

## 🎯 Overview

This guide covers setting up AWS API Gateway to connect your S3-hosted frontend to your EC2 backend, with direct S3 photo upload capabilities for event images.

## 📋 What This Does

### API Gateway Features:
1. **Unified API Endpoint** - Single HTTPS URL for all API calls
2. **Cognito Integration** - Automatic JWT validation for protected endpoints
3. **VPC Link** - Secure connection to private backend EC2 instances
4. **Direct S3 Upload** - Photo uploads go directly to S3 (bypassing backend)
5. **CORS Support** - Properly configured cross-origin requests
6. **Rate Limiting** - Built-in throttling and usage plans
7. **Monitoring** - CloudWatch logs and metrics

### Endpoints Created:

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/api/events` | None | List all events (with pagination) |
| POST | `/api/events` | Cognito | Create new event (organizers only) |
| GET | `/api/events/{id}` | None | Get event details |
| GET | `/api/events/me` | Cognito | My events (organizer view) |
| POST | `/api/events/{id}/photo` | Cognito | Upload event photo to S3 |
| GET | `/api/events/{id}/photo` | None | Get event photo URL |
| POST | `/api/auth/register` | None | Register new user |
| POST | `/api/auth/login` | None | Login user |

## 🏗️ Architecture

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │
┌──────▼──────────────────┐
│  S3 Static Website      │ (Frontend)
│  or CloudFront          │
└──────┬──────────────────┘
       │ HTTPS
┌──────▼──────────────────┐
│  API Gateway (HTTPS)    │
│  - Cognito Authorizer   │
│  - Rate Limiting        │
│  - CORS                 │
└──────┬─────────┬────────┘
       │         │
       │         │ Direct Upload
       │         │
┌──────▼─────┐   │
│  VPC Link  │   │
└──────┬─────┘   │
       │         │
┌──────▼─────┐   ▼
│   ALB      │  S3 Event Pictures
└──────┬─────┘  (Direct from API Gateway)
       │
┌──────▼─────┐
│ EC2 Backend│
│ Auto Scaling│
└──────┬─────┘
       │
┌──────▼─────┬──────────┐
│ RDS MySQL  │  Redis   │
└────────────┴──────────┘
```

## 🚀 Deployment Steps

### Step 1: Update Backend Configuration

Add S3 configuration to `application.properties`:

```properties
# AWS S3 Configuration
aws.region=us-east-1
aws.s3.event-pictures-bucket=${EVENT_PICTURES_BUCKET}

# Multipart file upload
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

### Step 2: Add AWS SDK Dependency

Edit `main_backend/pom.xml` and add:

```xml
<!-- AWS SDK for S3 -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.20.0</version>
</dependency>
```

### Step 3: Run Database Migration

```bash
# Connect to your RDS MySQL database
mysql -h <RDS_ENDPOINT> -u admin -p

# Run the migration
source database-setup.sql/04_add_event_photo_columns.sql
```

Or update via Terraform (if using RDS with Terraform):

```bash
cd aws/
terraform apply -target=aws_db_instance.main
```

### Step 4: Deploy API Gateway Infrastructure

```bash
cd aws/

# Initialize Terraform (if needed)
terraform init

# Review the API Gateway resources
terraform plan

# Deploy API Gateway
terraform apply
```

This will create:
- API Gateway REST API
- VPC Link to backend
- Application Load Balancer
- Cognito Authorizer
- All API endpoints
- CloudWatch log groups

### Step 5: Get API Gateway URL

```bash
# Get the API Gateway URL
terraform output api_gateway_url

# Example output:
# https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

### Step 6: Update Frontend Configuration

Create `main_frontend/concert1/.env.production`:

```env
# API Gateway URL (from terraform output)
NUXT_PUBLIC_API_BASE_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod

# Cognito Configuration (already exists)
NUXT_PUBLIC_COGNITO_REGION=us-east-1
NUXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_TpsZkFbqO
NUXT_PUBLIC_COGNITO_CLIENT_ID=1eomnjf6812g8npdr8ta8naem7
```

### Step 7: Rebuild and Deploy Backend

```bash
cd main_backend/

# Build with new S3 dependencies
mvn clean package -DskipTests

# Deploy to EC2 (via CI/CD or manual)
# The CI/CD pipeline will pick this up automatically
```

### Step 8: Test API Gateway

```bash
# Test public endpoint (list events)
curl https://abc123.execute-api.us-east-1.amazonaws.com/prod/api/events

# Test auth endpoint
curl -X POST https://abc123.execute-api.us-east-1.amazonaws.com/prod/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"password"}'

# Test protected endpoint (requires JWT token)
TOKEN="<your-jwt-token>"
curl https://abc123.execute-api.us-east-1.amazonaws.com/prod/api/events/me \
  -H "Authorization: Bearer $TOKEN"

# Test photo upload
curl -X POST https://abc123.execute-api.us-east-1.amazonaws.com/prod/api/events/123/photo \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@event-image.jpg"
```

## 🖼️ Event Photo Upload API

### Upload Photo (Frontend Example)

```typescript
// composables/useEventPhoto.ts
export const useEventPhoto = () => {
  const config = useRuntimeConfig();
  const { getAccessToken } = useAuth();

  const uploadEventPhoto = async (eventId: number, file: File) => {
    const token = await getAccessToken();
    
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(
      `${config.public.apiBaseUrl}/api/events/${eventId}/photo`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        },
        body: formData
      }
    );

    if (!response.ok) {
      throw new Error('Photo upload failed');
    }

    return await response.json();
  };

  const getEventPhoto = async (eventId: number) => {
    const response = await fetch(
      `${config.public.apiBaseUrl}/api/events/${eventId}/photo`
    );

    if (!response.ok) {
      return null;
    }

    return await response.json();
  };

  return {
    uploadEventPhoto,
    getEventPhoto
  };
};
```

### Usage in Component

```vue
<!-- pages/events/[id]/edit.vue -->
<template>
  <div>
    <h2>Upload Event Photo</h2>
    <input 
      type="file" 
      @change="handleFileSelect" 
      accept="image/*"
    />
    <button @click="uploadPhoto" :disabled="!selectedFile || uploading">
      {{ uploading ? 'Uploading...' : 'Upload Photo' }}
    </button>

    <div v-if="eventPhoto">
      <img :src="eventPhoto.photoUrl" alt="Event Photo" />
    </div>
  </div>
</template>

<script setup lang="ts">
const route = useRoute();
const eventId = Number(route.params.id);

const { uploadEventPhoto, getEventPhoto } = useEventPhoto();

const selectedFile = ref<File | null>(null);
const uploading = ref(false);
const eventPhoto = ref(null);

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    selectedFile.value = target.files[0];
  }
};

const uploadPhoto = async () => {
  if (!selectedFile.value) return;

  try {
    uploading.value = true;
    const response = await uploadEventPhoto(eventId, selectedFile.value);
    eventPhoto.value = response;
    alert('Photo uploaded successfully!');
  } catch (error) {
    alert('Failed to upload photo');
  } finally {
    uploading.value = false;
  }
};

// Load existing photo on mount
onMounted(async () => {
  eventPhoto.value = await getEventPhoto(eventId);
});
</script>
```

## 📊 API Gateway Features

### 1. Cognito Authorization

Protected endpoints automatically validate JWT tokens:

```javascript
// Frontend: Include token in Authorization header
headers: {
  'Authorization': `Bearer ${jwtToken}`
}
```

API Gateway validates token against Cognito User Pool before forwarding to backend.

### 2. Rate Limiting

Default usage plan:
- **Rate Limit**: 50 requests/second
- **Burst Limit**: 100 requests
- **Daily Quota**: 10,000 requests/day

To modify, edit `aws/api_gateway.tf`:

```hcl
resource "aws_api_gateway_usage_plan" "main" {
  throttle_settings {
    burst_limit = 200  # Increase burst
    rate_limit  = 100  # Increase rate
  }

  quota_settings {
    limit  = 50000  # Increase daily quota
    period = "DAY"
  }
}
```

### 3. CORS Configuration

All endpoints support CORS with:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`

### 4. CloudWatch Monitoring

View API Gateway logs:

```bash
# AWS Console
CloudWatch → Log Groups → /aws/apigateway/concert-dev

# Or via AWS CLI
aws logs tail /aws/apigateway/concert-dev --follow
```

Metrics available:
- Request count
- Latency (API Gateway + backend)
- 4XX/5XX errors
- Cache hit/miss (if caching enabled)

## 🔐 Security Features

### VPC Link

API Gateway connects to backend via **VPC Link** to internal ALB:
- Backend EC2 instances in private subnets
- No direct internet exposure
- ALB only accessible from VPC Link

### S3 Photo Upload Security

- **Authentication Required**: Only logged-in users can upload
- **Organizer Verification**: Backend verifies user owns the event
- **File Size Limits**: 10MB max (configurable)
- **Content Type Validation**: Only images accepted
- **Per-Event Folders**: Photos stored as `events/{eventId}/{uuid}.jpg`

### IAM Permissions

API Gateway has minimal S3 permissions:
- `s3:PutObject` - Upload photos
- `s3:GetObject` - Read photos
- Only on `event-pictures` bucket

## 💰 Cost Estimates

### API Gateway Pricing (us-east-1)

**Free Tier** (first 12 months):
- 1 million API calls/month

**After Free Tier**:
- $3.50 per million API calls
- $0.09/GB data transfer out

**Example** (10,000 users, 100 requests/day each):
- 1 million requests/day = 30M requests/month
- Cost: 30M * $3.50 / 1M = **$105/month**
- Data transfer (1KB/response): 30M * 1KB = 30GB = **$2.70/month**
- **Total**: ~$108/month

### VPC Link Pricing

- $0.01/hour = **$7.20/month**

### Combined Monthly Cost

| Service | Cost |
|---------|------|
| API Gateway | $105 |
| Data Transfer | $2.70 |
| VPC Link | $7.20 |
| ALB | $16.20 |
| **Total** | **~$131/month** |

## 🛠️ Troubleshooting

### Issue 1: 403 Forbidden on Protected Endpoints

**Cause**: JWT token invalid or expired

**Solution**:
```javascript
// Check token expiration
const token = localStorage.getItem('token');
const decoded = JSON.parse(atob(token.split('.')[1]));
console.log('Token expires:', new Date(decoded.exp * 1000));

// Refresh token if expired
if (decoded.exp * 1000 < Date.now()) {
  // Refresh logic here
}
```

### Issue 2: CORS Errors

**Cause**: Missing or incorrect CORS headers

**Solution**: Check API Gateway CORS configuration

```bash
# Test CORS preflight
curl -X OPTIONS https://api-url/api/events \
  -H "Origin: https://your-frontend.com" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

Should return:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET,POST,OPTIONS
```

### Issue 3: Photo Upload Fails

**Cause**: File too large or wrong content type

**Solution**: Check file size and type

```javascript
// Frontend validation
if (file.size > 10 * 1024 * 1024) {
  alert('File must be less than 10MB');
  return;
}

if (!file.type.startsWith('image/')) {
  alert('File must be an image');
  return;
}
```

### Issue 4: VPC Link Timeout

**Cause**: Backend EC2 not responding

**Solution**: Check backend health

```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>

# Should show 'healthy' status
```

## 📈 Monitoring and Alerts

### CloudWatch Alarms

```bash
# Create alarm for high error rate
aws cloudwatch put-metric-alarm \
  --alarm-name api-gateway-high-errors \
  --alarm-description "API Gateway error rate > 5%" \
  --metric-name 5XXError \
  --namespace AWS/ApiGateway \
  --statistic Average \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### Dashboard Metrics

Monitor in CloudWatch:
- API call volume
- Latency (p50, p95, p99)
- Error rates (4XX, 5XX)
- Cache hit ratio (if caching)
- VPC Link status

## 🔄 Update Procedures

### Add New Endpoint

1. Edit `aws/api_gateway.tf`
2. Add resource and method
3. Add integration
4. Add CORS module
5. Deploy:

```bash
terraform apply
```

### Update Backend URL

```bash
# If backend ALB changes
terraform taint aws_api_gateway_integration.events_get
terraform apply
```

## ✅ Next Steps

After API Gateway is deployed:

1. ✅ **Test All Endpoints** - Use Postman or curl
2. ✅ **Update Frontend** - Point to API Gateway URL
3. ✅ **Enable CloudWatch Alarms** - Monitor errors
4. ✅ **Test Photo Upload** - Upload event images
5. ✅ **Load Testing** - Verify rate limits work
6. ✅ **Custom Domain** (Optional) - Add Route 53 + ACM certificate

## 📚 References

- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [VPC Link Setup](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)
- [Cognito Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html)
- [S3 Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/integrating-api-with-aws-services-s3.html)

---

**Last Updated**: November 1, 2025  
**Status**: Ready to Deploy ✅
