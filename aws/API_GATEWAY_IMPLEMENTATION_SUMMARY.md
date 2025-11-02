# API Gateway Implementation Summary

## ✅ What Was Created

### 1. AWS Infrastructure (`aws/api_gateway.tf`)
Complete AWS API Gateway setup with:
- **REST API Gateway** with regional endpoint
- **10 API Resources** (paths): `/api/events`, `/api/events/{id}`, `/api/events/me`, `/api/events/{id}/photo`, `/api/auth/login`, etc.
- **Cognito Authorizer** for protected endpoints
- **VPC Link** to connect to private backend EC2 instances
- **Application Load Balancer** for backend EC2 Auto Scaling Group
- **Direct S3 Integration** for event photo uploads
- **CORS support** on all endpoints
- **Usage Plan** with rate limiting (50 req/sec, 10K/day)
- **CloudWatch Logs** for monitoring

### 2. Backend Updates

#### New Files:
- `EventPhotoResponse.java` - DTO for photo upload responses
- `S3Config.java` - AWS S3 client configuration

#### Updated Files:
- `Event.java` - Added `photoId` and `photoUrl` fields
- `EventResponse.java` - Added `photoId` and `photoUrl` fields
- `EventController.java` - Added photo upload endpoints
- `EventService.java` - Added S3 upload logic

### 3. Database Migration
- `04_add_event_photo_columns.sql` - Adds photo_id and photo_url columns to events table

### 4. Documentation
- `API_GATEWAY_SETUP_GUIDE.md` - Complete setup and usage guide

## 🎯 API Endpoints Created

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| GET | `/api/events` | None | List all events (paginated) |
| POST | `/api/events` | Cognito JWT | Create new event |
| GET | `/api/events/{id}` | None | Get event details |
| GET | `/api/events/me` | Cognito JWT | Get my events (organizer) |
| **POST** | **/api/events/{id}/photo** | **Cognito JWT** | **Upload event photo** |
| **GET** | **/api/events/{id}/photo** | **None** | **Get event photo URL** |
| POST | `/api/auth/register` | None | Register user |
| POST | `/api/auth/login` | None | Login user |

## 🖼️ Event Photo Feature

### How It Works:

1. **Frontend** uploads photo to API Gateway
2. **API Gateway** validates JWT token (Cognito)
3. **Request forwarded** to backend EC2
4. **Backend verifies** user owns the event
5. **Photo uploaded** directly to S3 event-pictures bucket
6. **Database updated** with `photo_id` and `photo_url`
7. **Response** returns public S3 URL

### S3 Structure:
```
s3://concert-event-pictures-useast1-123456789012/
└── events/
    ├── 123/
    │   └── uuid-abc-123.jpg
    ├── 124/
    │   └── uuid-def-456.jpg
    └── 125/
        └── uuid-ghi-789.jpg
```

### Security:
- ✅ Only authenticated users can upload
- ✅ Only event organizers can upload photos to their events
- ✅ 10MB file size limit
- ✅ Image files only (MIME type validation)
- ✅ Unique UUIDs prevent overwrites
- ✅ Per-event folders for organization

## 📦 Dependencies Required

Add to `main_backend/pom.xml`:

```xml
<!-- AWS SDK for S3 -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.20.0</version>
</dependency>
```

## ⚙️ Configuration Required

Add to `main_backend/src/main/resources/application.properties`:

```properties
# AWS S3 Configuration
aws.region=us-east-1
aws.s3.event-pictures-bucket=${EVENT_PICTURES_BUCKET}

# Multipart file upload
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=10MB
```

## 🚀 Deployment Steps

### 1. Update Backend Dependencies
```bash
cd main_backend/
mvn clean install
```

### 2. Run Database Migration
```bash
mysql -h <RDS_ENDPOINT> -u admin -p < database-setup.sql/04_add_event_photo_columns.sql
```

### 3. Deploy API Gateway
```bash
cd aws/
terraform init
terraform plan
terraform apply
```

### 4. Get API Gateway URL
```bash
terraform output api_gateway_url
# Output: https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

### 5. Update Frontend .env
```env
NUXT_PUBLIC_API_BASE_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

### 6. Rebuild & Deploy Backend
```bash
cd main_backend/
mvn clean package -DskipTests
# Deploy via CI/CD or manually to EC2
```

## 🧪 Testing

### Test Event Photo Upload:

```bash
# 1. Login to get token
TOKEN=$(curl -X POST https://api-url/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"password"}' \
  | jq -r '.token')

# 2. Create an event
EVENT_ID=$(curl -X POST https://api-url/api/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Concert",
    "description": "Test event",
    "startDate": "2025-12-01T19:00:00",
    "endDate": "2025-12-01T23:00:00",
    "personLimit": 100
  }' | jq -r '.id')

# 3. Upload photo
curl -X POST https://api-url/api/events/$EVENT_ID/photo \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@event-photo.jpg"

# 4. Get photo URL
curl https://api-url/api/events/$EVENT_ID/photo
```

### Expected Response:

```json
{
  "photoUrl": "https://concert-event-pictures-useast1-123456789012.s3.us-east-1.amazonaws.com/events/123/abc-123-def.jpg",
  "photoId": "events/123/abc-123-def.jpg",
  "message": "Photo uploaded successfully"
}
```

## 🎨 Frontend Integration Example

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
        headers: { 'Authorization': `Bearer ${token}` },
        body: formData
      }
    );

    return await response.json();
  };

  return { uploadEventPhoto };
};
```

```vue
<!-- components/EventPhotoUpload.vue -->
<template>
  <div>
    <input type="file" @change="handleFileSelect" accept="image/*" />
    <button @click="upload" :disabled="!file">Upload Photo</button>
    <img v-if="photoUrl" :src="photoUrl" alt="Event Photo" />
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ eventId: number }>();
const { uploadEventPhoto } = useEventPhoto();

const file = ref<File | null>(null);
const photoUrl = ref<string | null>(null);

const handleFileSelect = (e: Event) => {
  const target = e.target as HTMLInputElement;
  file.value = target.files?.[0] || null;
};

const upload = async () => {
  if (!file.value) return;
  const response = await uploadEventPhoto(props.eventId, file.value);
  photoUrl.value = response.photoUrl;
};
</script>
```

## 💡 Key Features

### 1. **Unified API Endpoint**
- Single HTTPS URL for all API calls
- No need to know backend EC2 IP addresses
- Easy to update backend without changing frontend

### 2. **Automatic Authentication**
- Cognito JWT tokens validated by API Gateway
- No authentication code needed in backend
- Protected endpoints automatically secured

### 3. **Direct S3 Upload** (Optional Path)
- Photos uploaded directly to S3 via API Gateway
- No backend processing required
- Faster uploads, lower backend load
- Backend only validates ownership

### 4. **Rate Limiting**
- Prevents API abuse
- 50 requests/second per user
- 100 burst capacity
- 10,000 requests/day quota

### 5. **Monitoring**
- All requests logged to CloudWatch
- Metrics: latency, errors, request count
- Easy troubleshooting

## 📊 Architecture Diagram

```
Frontend (S3/CloudFront)
        ↓
API Gateway (HTTPS)
        ↓
   ┌────┴────┐
   │         │
VPC Link   Direct Upload
   │         ↓
   ↓      S3 (Event Photos)
  ALB
   ↓
EC2 Backend
   ↓
RDS MySQL
(Stores photo_id, photo_url)
```

## 💰 Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| API Gateway (30M req/month) | $105 |
| Data Transfer | $3 |
| VPC Link | $7 |
| ALB | $16 |
| **Total Added Cost** | **~$131/month** |

## ✅ Benefits

1. **Professional API Structure** - RESTful endpoints
2. **HTTPS Everywhere** - Secure by default
3. **Scalable** - API Gateway handles millions of requests
4. **Monitored** - CloudWatch logs and metrics
5. **Cost Effective** - Pay per request
6. **Easy Frontend Updates** - Single API URL
7. **Photo Management** - S3 integration for event images
8. **Security** - Cognito JWT validation built-in

## 🔄 Next Steps

1. Deploy API Gateway: `terraform apply`
2. Add AWS SDK dependency to backend
3. Run database migration
4. Update frontend API base URL
5. Test photo upload functionality
6. Monitor CloudWatch logs
7. (Optional) Add custom domain with Route 53

## 📝 Files Modified/Created

```
aws/
├── api_gateway.tf (NEW) ← API Gateway infrastructure
└── API_GATEWAY_SETUP_GUIDE.md (NEW) ← Complete guide

main_backend/src/main/java/com/concert/
├── config/
│   └── S3Config.java (NEW) ← S3 client configuration
├── controller/
│   └── EventController.java (UPDATED) ← Added photo endpoints
├── dto/
│   ├── EventResponse.java (UPDATED) ← Added photo fields
│   └── EventPhotoResponse.java (NEW) ← Photo upload response
├── model/
│   └── Event.java (UPDATED) ← Added photoId, photoUrl
└── service/
    └── EventService.java (UPDATED) ← Added S3 upload logic

database-setup.sql/
└── 04_add_event_photo_columns.sql (NEW) ← Database migration
```

---

**Status**: ✅ Ready to Deploy  
**Last Updated**: November 1, 2025
