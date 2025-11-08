# Image Upload Solution for HTTPS Website

## Problem
- Website uses HTTPS (CloudFront)
- S3 bucket uses HTTP URLs
- Browsers block mixed content (HTTPS page loading HTTP images)

## Solution: Use Image URLs (No File Upload)

### ✅ Current Implementation

**Users paste HTTPS image URLs** from free image sites:
- Unsplash.com
- Pexels.com
- Pixabay.com

**Benefits:**
- ✅ No S3 upload complexity
- ✅ No CORS issues
- ✅ No mixed content warnings
- ✅ Free high-quality images
- ✅ Works immediately
- ✅ No storage costs

### How Users Add Photos

1. Visit: https://d3jivuimmea02r.cloudfront.net/UploadPhotoPage
2. Login with credentials
3. Enter Event ID
4. Paste HTTPS image URL
5. Click "Set Photo URL"

### Example Image URLs

```
https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800
https://images.pexels.com/photos/1105666/pexels-photo-1105666.jpeg
https://cdn.pixabay.com/photo/2016/11/23/15/48/audience-1853662_1280.jpg
```

## Alternative: File Upload with CloudFront (Future)

If you need actual file uploads:

### Option 1: CloudFront + S3 (Recommended)
- Upload files to S3
- Serve via CloudFront HTTPS URL
- CloudFront URL: `https://dzh397ixo71bk.cloudfront.net/events/{id}/{filename}`

### Option 2: Direct S3 Upload with Presigned URLs
- Backend generates presigned S3 URL
- Frontend uploads directly to S3
- Backend saves CloudFront URL to database

### Implementation Steps (If Needed)

1. **Update Backend** - Add photoUrl field support in updateEvent
2. **Configure S3** - Enable CORS for browser uploads
3. **Use CloudFront URLs** - Always use HTTPS CloudFront domain
4. **Frontend Upload** - Use presigned URLs for direct S3 upload

## Current Status

✅ **Working**: Image URLs stored in database
✅ **Working**: Images display via HTTPS
✅ **Working**: 5 events have photos
✅ **Working**: Users can add photos via URL

## Database Schema

```sql
events table:
- event_id (bigint, primary key)
- photo_url (varchar(255)) -- Stores HTTPS image URL
- photo_id (varchar(255)) -- Optional S3 key
```

## CloudFront Distributions

- **Frontend**: E1KJ1O0NQAT0B9 (d3jivuimmea02r.cloudfront.net)
- **Backend**: REDACTED_RESOURCE_ID (d3qkurc1gwuwno.cloudfront.net)
- **Images**: E1AOTTQDI43845 (dzh397ixo71bk.cloudfront.net)

## Recommendation

**Keep current URL-based approach** because:
1. Simpler for users
2. No upload complexity
3. No storage costs
4. Professional images from Unsplash
5. Works perfectly with HTTPS

Only implement file upload if users specifically need to upload their own photos.
