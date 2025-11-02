# Manual Backend Deployment Guide

## Quick Deployment via AWS Console

### Option 1: EC2 Instance Connect (Easiest - No SSH Key Needed)

1. **Go to AWS Console**
   - Navigate to: https://console.aws.amazon.com/ec2/
   - Login with your credentials

2. **Connect to Instance**
   - Click on instance `i-0516e976bbcbda128` (52.203.64.85)
   - Click "Connect" button (top right)
   - Select "EC2 Instance Connect" tab
   - Click "Connect" button

3. **Run Deployment Commands**
   Copy and paste these commands one by one:

```bash
# Download new JAR from S3
aws s3 cp s3://concert-dev-frontend-142fee22/deployments/concert-backend-1.0.0.jar /tmp/concert-backend-1.0.0.jar --region us-east-1

# Stop the backend service
sudo systemctl stop concert-backend

# Backup old JAR (optional but recommended)
sudo cp /opt/concert/concert-backend-1.0.0.jar /opt/concert/concert-backend-1.0.0.jar.backup

# Replace with new JAR
sudo mv /tmp/concert-backend-1.0.0.jar /opt/concert/concert-backend-1.0.0.jar

# Start the backend service
sudo systemctl start concert-backend

# Wait a moment for service to start
sleep 5

# Check if service is running
sudo systemctl status concert-backend

# View logs (optional - to see if it started correctly)
sudo journalctl -u concert-backend -n 50 --no-pager
```

4. **Verify Deployment**
   Look for:
   - `Active: active (running)` in the status output
   - No errors in the logs

### Option 2: Session Manager (Alternative)

1. Go to AWS Systems Manager Console
2. Click "Session Manager" in left menu
3. Click "Start session"
4. Select instance `i-0516e976bbcbda128`
5. Click "Start session"
6. Run the same commands as Option 1

---

## Testing After Deployment

### 1. Test GET /api/users/me Endpoint

Open terminal on your local machine:

```bash
# Register a new user
curl -X POST http://52.203.64.85:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testdeploy","email":"testdeploy@test.com","password":"REDACTED_PASSWORD_D"}' \
  | jq .
```

You should get a response with a token. Copy the token.

```bash
# Test the new GET endpoint (replace YOUR_TOKEN with the actual token)
curl -X GET http://52.203.64.85:8080/api/users/me \
  -H "Authorization: Bearer YOUR_TOKEN" \
  | jq .
```

Expected response:
```json
{
  "id": 123,
  "username": "testdeploy",
  "email": "testdeploy@test.com",
  "name": null,
  "phone": null,
  ...
}
```

### 2. Test Frontend

1. **Clear browser cache:** `Cmd + Shift + R` (Mac) or `Ctrl + Shift + R` (Windows)

2. **Go to registration page:**
   http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/RegisterPage

3. **Register a new user**

4. **Login** with your new credentials

5. **Go to Account page** → Should load your profile data

6. **Click "Edit Profile"**
   - Fill in: First Name, Last Name, Phone, etc.
   - Click "Save Changes"
   - Should show success message

7. **Refresh page** → Data should persist

---

## Troubleshooting

### If backend won't start:

```bash
# Check detailed logs
sudo journalctl -u concert-backend -n 100 --no-pager

# Check if port 8080 is in use
sudo netstat -tlnp | grep 8080

# Check Java version
java -version

# Manually test the JAR
cd /opt/concert
java -jar concert-backend-1.0.0.jar
```

### If you see "Not Found" on Account page:

1. Make sure backend is deployed (check timestamp on JAR file)
2. Clear browser cache completely
3. Make sure you're logged in (check localStorage for JWT token)
4. Check browser console for errors

### Check JAR file timestamp:

```bash
ls -lh /opt/concert/
```

You should see the JAR file with today's date/time.

---

## What Changed in This Deployment

**Added Endpoint:** `GET /api/users/me`

**Location:** `UserController.java` lines 43-72

**Functionality:**
- Returns current user's profile data
- Uses JWT token to identify user
- Returns UserProfileResponse with all fields

**Before:** Frontend couldn't load user data on Account page
**After:** Frontend loads and displays user data automatically

---

## AWS Credentials Info

Your deployment user credentials:
- **Access Key ID:** REDACTED_AWS_ACCESS_KEY_ID
- **User:** Deploymen
- **Account:** 123456789012

These credentials work for AWS CLI/API access but not for SSH.
For SSH-like access, use EC2 Instance Connect via AWS Console.
