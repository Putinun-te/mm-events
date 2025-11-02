# Concert Platform - Deployment Status & Testing Guide

## Date: November 2, 2025

## Issues Found & Fixed

### 1. Frontend - UserProfile Loading ✅ FIXED
**Problem:** UserProfile component didn't load user data from backend
**Solution:** Added `loadProfile()` function that calls `GET /api/users/me` on component mount
**Status:** Deployed to S3 (Build: a445a95d-fd95-4740-958c-5ac8fc5ab424)

### 2. Backend - Missing GET Endpoint ✅ FIXED (NEEDS DEPLOYMENT)
**Problem:** Backend had `PUT /api/users/me` but no `GET /api/users/me`
**Solution:** Added GET endpoint in UserController.java (lines 43-72)
**Status:** ⚠️ Code ready, JAR uploaded to S3, **NEEDS EC2 DEPLOYMENT**

## Current Status

### Frontend (S3)
- **URL:** http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/
- **Build ID:** a445a95d-fd95-4740-958c-5ac8fc5ab424
- **Status:** ✅ DEPLOYED
- **Features:**
  - Login: Username/Email support + password toggle
  - Register: Password toggle
  - UserProfile: Loads data from backend on mount
  - Error handling: Shows "Not Found" if user doesn't exist

### Backend (EC2)
- **URL:** http://52.203.64.85:8080
- **Instance ID:** i-0516e976bbcbda128
- **Status:** ⚠️ **OLD VERSION** - Needs deployment of new JAR
- **New JAR Location:** s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar

## Required: Deploy Backend to EC2

The new backend JAR with `GET /api/users/me` endpoint is ready but needs to be deployed to EC2.

### Manual Deployment Steps (if SSM fails):

```bash
# 1. SSH to EC2 (if you have access)
ssh -i your-key.pem ec2-user@52.203.64.85

# 2. Download new JAR from S3
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /tmp/

# 3. Stop service
sudo systemctl stop concert-backend

# 4. Replace JAR
sudo mv /tmp/concert-backend-1.0.0.jar /opt/concert/concert-backend-1.0.0.jar

# 5. Start service
sudo systemctl start concert-backend

# 6. Check status
sudo systemctl status concert-backend
sudo journalctl -u concert-backend -f
```

### Alternative: Use EC2 Instance Connect (no keys needed)

```bash
# Use AWS console EC2 Instance Connect to access the instance
# Then run the commands above
```

## Testing Guide

### Step 1: Register a New User

```bash
curl -X POST http://52.203.64.85:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"demouser","email":"demo@test.com","password":"Demo1234"}' \
  | jq .
```

Expected response:
```json
{
  "token": "eyJhbG...",
  "type": "Bearer",
  "username": "demouser",
  "email": "demo@test.com",
  "message": null
}
```

### Step 2: Test GET /api/users/me (After Backend Deployment)

```bash
# Use the token from step 1
curl -X GET http://52.203.64.85:8080/api/users/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  | jq .
```

Expected response:
```json
{
  "id": 123,
  "username": "demouser",
  "email": "demo@test.com",
  "name": null,
  "phone": null,
  "address": null,
  "city": null,
  "country": null,
  "pincode": null,
  "profilePhoto": null,
  "company": null,
  "website": null
}
```

### Step 3: Update Profile

```bash
curl -X PUT http://52.203.64.85:8080/api/users/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Demo",
    "lastName": "User",
    "phone": "+1234567890",
    "address": "123 Main St",
    "website": "https://example.com"
  }' \
  | jq .
```

### Step 4: Test Frontend Flow

1. **Clear browser cache:** Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
2. **Go to:** http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/LoginPage
3. **Register new user:** Click "Sign Up" → Fill form → Register
4. **Login:** Use credentials from step 3
5. **Go to Account page:** Click profile icon → Account
6. **Expected:** Profile loads with your data (or shows empty fields for new user)
7. **Edit profile:** Click "Edit Profile" → Fill fields → "Save Changes"
8. **Expected:** Success message + data persists

## Known Issues

### Issue: "Not Found" Error on Account Page
**Cause:** One of these:
1. Backend not updated (missing GET /api/users/me endpoint) ← **CURRENT ISSUE**
2. User not logged in (no JWT token)
3. User doesn't exist in database

**Solution:**
1. Deploy new backend JAR to EC2 (see deployment steps above)
2. Clear browser cache
3. Login first, then visit Account page

## Database Info

### Sample Users (from init.sql)
**Password for all:** `password123`

- alice.johnson@example.com
- bob.smith@example.com
- charlie.brown@example.com
... (20 users total)

### Test User Created
- **Username:** newuser123
- **Email:** newuser123@test.com
- **Password:** Pass1234
- **Note:** This user was created during testing

## Next Steps

1. ✅ Frontend deployed with profile loading
2. ✅ Backend code updated with GET endpoint
3. ⏳ **PENDING:** Deploy backend JAR to EC2
4. ⏳ **PENDING:** Test complete flow (register → login → view profile → edit profile)
5. ⏳ **PENDING:** Verify all features work end-to-end

## Files Modified

### Backend
- `main_backend/src/main/java/com/concert/controller/UserController.java`
  - Added `GET /api/users/me` endpoint (lines 43-72)

### Frontend
- `main_frontend/concert1/app/components/UserProfile.vue`
  - Added `loadProfile()` function
  - Added `onMounted()` lifecycle hook
  - Added loading and error states

## Contact Info

- **EC2 Instance:** 52.203.64.85:8080
- **S3 Frontend:** concert-dev-frontend-142fee22
- **RDS Database:** concert-db.csfsyoiy61fp.us-east-1.rds.amazonaws.com
- **Region:** us-east-1
