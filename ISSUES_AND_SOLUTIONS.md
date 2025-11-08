# 🔧 Issues and Solutions

## Issue 1: Events Don't Appear with Photos

### Problem
Events are not displaying photos on the event list and detail pages.

### Root Cause
Existing events in the database don't have photos uploaded. The events were created without photos, so `photoUrl` and `photoId` fields are `null`.

### Solution
**Option 1: Create New Events with Photos (Recommended)**
1. Go to https://d3jivuimmea02r.cloudfront.net
2. Login with test credentials
3. Click "Create Event"
4. Fill in all event details
5. **Upload a photo** using the "Upload Picture" button
6. Submit the event

**Option 2: Edit Existing Events and Add Photos**
1. Go to "My Events" page
2. Click "Edit" on any event
3. Upload a photo using the photo upload section
4. Save the event

### Verification
```bash
# Check if events have photos
curl -s https://d3qkurc1gwuwno.cloudfront.net/api/events | jq '.content[] | {id, title, photoUrl}'
```

---

## Issue 2: S3 Buckets in us-east-1 (Cost Optimization)

### Problem
S3 buckets were in us-east-1 while EC2 and RDS were in Singapore, causing:
- Cross-region data transfer costs
- Higher latency
- Unnecessary complexity

### Solution ✅ COMPLETED
1. Created new S3 buckets in Singapore:
   - concert-event-pictures-singapore-123456789012
   - concert-user-avatars-singapore-123456789012
   - concert-web-singapore-123456789012

2. Migrated all data from us-east-1 to Singapore

3. Updated backend configuration to use Singapore buckets

4. Deleted old us-east-1 buckets

### Verification
```bash
# List Singapore buckets
aws s3 ls | grep singapore

# Check backend configuration
ssh -i concert-singapore.pem ubuntu@13.250.108.116 'docker inspect concert-backend | grep S3'
```

---

## Issue 3: Cognito User Pool in us-east-1 (Unused Service)

### Problem
Cognito user pool was configured but not being used. The application uses JWT authentication instead, causing:
- Unnecessary AWS costs (~$5/month)
- Unused service in us-east-1
- Configuration complexity

### Solution ✅ COMPLETED
1. Verified Cognito is not used in authentication flow
2. Disabled deletion protection
3. Deleted Cognito user pool (us-east-1_nTZpyinXc)

### Verification
```bash
# Check if Cognito exists
aws cognito-idp list-user-pools --max-results 10 --region us-east-1
```

---

## Issue 4: ElastiCache/Redis Not Used

### Problem
Backend was trying to connect to Redis (localhost:6379) but Redis was not running, causing:
- Health check failures
- Error logs
- Unnecessary dependency

### Solution ✅ COMPLETED
1. Disabled Redis in backend configuration:
   ```bash
   SPRING_DATA_REDIS_HOST=none
   SPRING_AUTOCONFIGURE_EXCLUDE=org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration
   ```

2. Restarted backend with updated configuration

### Verification
```bash
# Check backend health
curl https://d3qkurc1gwuwno.cloudfront.net/actuator/health

# Check logs for Redis errors
ssh -i concert-singapore.pem ubuntu@13.250.108.116 'docker logs concert-backend 2>&1 | grep -i redis'
```

---

## Current Status

### ✅ Working
- Backend API (all CRUD endpoints)
- Frontend website
- User authentication (JWT)
- Event creation
- Event editing
- Event deletion
- Photo upload (for new events)
- All services in Singapore
- Cost optimized

### ⚠️ Needs Testing
- Create new event with photo
- Edit event and add photo
- Verify photos display correctly
- Test booking flow

### 📝 Recommendations

1. **Create Test Events with Photos**
   - Create 3-5 new events with photos
   - Test different categories
   - Verify photos display on event list and detail pages

2. **Update Existing Events**
   - Edit old events without photos
   - Add photos to them
   - Or delete old test events

3. **Monitor Costs**
   - Check AWS Cost Explorer after 24 hours
   - Verify no charges from deleted services
   - Monitor S3 storage and transfer costs

4. **Performance Testing**
   - Test photo upload speed
   - Verify CloudFront caching
   - Check page load times

---

## Quick Commands

### Create New Event with Photo
1. Visit: https://d3jivuimmea02r.cloudfront.net/CreateEventPage
2. Login if needed
3. Fill form and upload photo
4. Submit

### Check Backend Logs
```bash
ssh -i concert-singapore.pem ubuntu@13.250.108.116 'docker logs --tail 100 concert-backend'
```

### Check S3 Buckets
```bash
aws s3 ls concert-event-pictures-singapore-123456789012
aws s3 ls concert-user-avatars-singapore-123456789012
```

### Restart Backend
```bash
ssh -i concert-singapore.pem ubuntu@13.250.108.116 'docker restart concert-backend'
```

---

**Last Updated:** November 7, 2025
