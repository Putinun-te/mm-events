# Presigned URL Upload Implementation Guide

## Overview

The photo upload has been changed to use **S3 presigned URLs** for direct client-to-S3 uploads. This eliminates backend memory overhead and database update issues.

## How It Works

```
1. Frontend requests upload URL from backend
2. Backend generates presigned S3 URL (valid for 15 minutes)
3. Frontend uploads file directly to S3 using presigned URL
4. Frontend confirms upload to backend
5. Backend updates database with photo URL
```

## API Endpoints

### 1. Get Upload URL
```http
POST /api/events/{eventId}/photo/upload-url?filename={filename}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "photoId": "events/10/photo-123.jpg",
  "uploadUrl": "https://concert-event-pictures-singapore-123456789012.s3.ap-southeast-1.amazonaws.com/events/10/photo-123.jpg?X-Amz-Algorithm=...",
  "message": "Upload URL generated"
}
```

### 2. Confirm Upload
```http
POST /api/events/{eventId}/photo?filename={filename}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "photoUrl": "https://concert-event-pictures-singapore-123456789012.s3.ap-southeast-1.amazonaws.com/events/10/photo-123.jpg",
  "photoId": "events/10/photo-123.jpg",
  "message": "Photo set successfully"
}
```

## Frontend Implementation

### Vue/Nuxt Example

```typescript
async function uploadEventPhoto(eventId: number, file: File) {
  try {
    const config = useRuntimeConfig()
    const token = localStorage.getItem('token')
    
    // Step 1: Get presigned upload URL
    const uploadUrlResponse = await $fetch(
      `${config.public.backendBaseUrl}/api/events/${eventId}/photo/upload-url`,
      {
        method: 'POST',
        params: { filename: file.name },
        headers: { Authorization: `Bearer ${token}` }
      }
    )
    
    // Step 2: Upload directly to S3
    await fetch(uploadUrlResponse.uploadUrl, {
      method: 'PUT',
      body: file,
      headers: {
        'Content-Type': file.type
      }
    })
    
    // Step 3: Confirm upload to backend
    const confirmResponse = await $fetch(
      `${config.public.backendBaseUrl}/api/events/${eventId}/photo`,
      {
        method: 'POST',
        params: { filename: file.name },
        headers: { Authorization: `Bearer ${token}` }
      }
    )
    
    console.log('Photo uploaded:', confirmResponse.photoUrl)
    return confirmResponse
    
  } catch (error) {
    console.error('Upload failed:', error)
    throw error
  }
}
```

### JavaScript Example

```javascript
async function uploadPhoto(eventId, file) {
  const token = localStorage.getItem('token')
  
  // Get upload URL
  const urlResponse = await fetch(
    `https://d3qkurc1gwuwno.cloudfront.net/api/events/${eventId}/photo/upload-url?filename=${file.name}`,
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }
  )
  const { uploadUrl, photoId } = await urlResponse.json()
  
  // Upload to S3
  await fetch(uploadUrl, {
    method: 'PUT',
    body: file,
    headers: { 'Content-Type': file.type }
  })
  
  // Confirm
  const confirmResponse = await fetch(
    `https://d3qkurc1gwuwno.cloudfront.net/api/events/${eventId}/photo?filename=${file.name}`,
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }
  )
  
  return await confirmResponse.json()
}
```

## Benefits

✅ **No Backend Memory Issues** - Files never pass through backend
✅ **No Database Update Failures** - Database only updated after successful S3 upload
✅ **Faster Uploads** - Direct to S3, no proxy
✅ **Lower Backend Load** - Backend only generates URLs
✅ **Secure** - Presigned URLs expire in 15 minutes
✅ **Cost Effective** - Reduces backend bandwidth and processing

## Migration Notes

### Old Endpoint (Deprecated)
```http
POST /api/events/{id}/photo
Content-Type: multipart/form-data
Body: file
```

### New Endpoints (Recommended)
```http
1. POST /api/events/{id}/photo/upload-url?filename=photo.jpg
2. PUT {presignedUrl} (direct to S3)
3. POST /api/events/{id}/photo?filename=photo.jpg
```

## Error Handling

```typescript
try {
  await uploadEventPhoto(eventId, file)
} catch (error) {
  if (error.status === 403) {
    console.error('Not authorized - check token')
  } else if (error.status === 404) {
    console.error('Event not found')
  } else {
    console.error('Upload failed:', error)
  }
}
```

## Testing

```bash
# Get upload URL
curl -X POST "https://d3qkurc1gwuwno.cloudfront.net/api/events/10/photo/upload-url?filename=test.jpg" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Upload to S3 (use uploadUrl from response)
curl -X PUT "PRESIGNED_URL" \
  --upload-file photo.jpg \
  -H "Content-Type: image/jpeg"

# Confirm upload
curl -X POST "https://d3qkurc1gwuwno.cloudfront.net/api/events/10/photo?filename=test.jpg" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## CloudFront URLs

- **Backend API**: https://d3qkurc1gwuwno.cloudfront.net
- **Frontend**: https://d3jivuimmea02r.cloudfront.net
- **Images**: https://dzh397ixo71bk.cloudfront.net

## Deployment Status

✅ Backend deployed with presigned URL support (Nov 8, 2025 14:41 UTC)
✅ Launch template v5 with proper AWS CLI installation
✅ Auto Scaling Group updated
✅ Health check passing
