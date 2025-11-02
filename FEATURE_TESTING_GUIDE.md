## 🚀 Complete Feature Testing Checklist

Since the backend needs manual deployment via AWS Console, here's what to do:

### Step 1: Deploy Backend (5 minutes)

**Quick Console Method:**
1. Open: https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#ConnectToInstance:instanceId=i-02883ae4914a92e3e
2. Click **"Connect"** using **EC2 Instance Connect**
3. Copy-paste the deployment command from `DEPLOY_BACKEND_NOW.md`
4. Wait 30 seconds
5. Test: `curl http://localhost:8080/api/auth/test`

### Step 2: Test All Features

Once backend is running, test these features on:
**http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/**

#### ✅ Authentication Features
- [ ] **Register** - Create new account (username, email, password)
  - Should redirect to login after success
  - Should validate email format
  - Should require password strength
  
- [ ] **Login** - Sign in with credentials
  - Should save token
  - Should redirect to home/dashboard
  - Should show user info
  
- [ ] **Logout** - Sign out
  - Should clear token
  - Should redirect to home

#### ✅ Event Management
- [ ] **View Events** - Browse event list
  - Should show event cards with images
  - Should display event details (name, date, price, location)
  
- [ ] **Create Event** (requires login)
  - Fill event details
  - Upload event photo
  - Set date, time, location
  - Set ticket price
  
- [ ] **Edit Event** (owner only)
  - Modify event details
  - Update photo
  
- [ ] **Delete Event** (owner only)
  - Remove event
  - Confirm deletion

#### ✅ Booking Features
- [ ] **Book Tickets** (requires login)
  - Select event
  - Choose quantity
  - Add to cart
  - Complete booking
  
- [ ] **View My Bookings**
  - See all your bookings
  - View booking details
  - Check booking status
  
- [ ] **Cancel Booking**
  - Cancel individual booking
  - Confirm cancellation

#### ✅ User Profile
- [ ] **View Profile**
  - See user information
  - View profile banner
  
- [ ] **Edit Profile**
  - Update username
  - Change email
  - Upload profile picture

#### ✅ Additional Features
- [ ] **Search Events** - Filter by name, date, location
- [ ] **Event Categories** - Browse by category
- [ ] **Cart Management** - Add/remove items
- [ ] **Payment** (if implemented)

### Expected URLs and Endpoints

**Frontend:** http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/

**Backend API:** http://44.215.145.187:8080
- Auth: `/api/auth/register`, `/api/auth/login`, `/api/auth/test`
- Events: `/api/events`, `/api/events/{id}`, `/api/events/{id}/photo`
- Bookings: `/api/bookings`, `/api/bookings/cancel/{id}`
- Users: `/api/users/me`, `/api/users/profile`

### Infrastructure Status

✅ **Working:**
- Frontend (S3 static website)
- RDS MySQL database
- ElastiCache Redis
- S3 buckets (events, avatars)
- Cognito (configured but using JWT)

⏳ **Pending:**
- Backend EC2 deployment (manual via console)
- CloudFront (waiting for AWS approval)
- API Gateway + ALB (waiting for AWS approval)

### Quick Commands

```bash
# Test backend
curl http://44.215.145.187:8080/api/auth/test

# Test frontend
curl -I http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com/

# Check backend logs (from EC2)
sudo journalctl -u concert-backend -f

# Restart backend (from EC2)
sudo systemctl restart concert-backend
```

### Known Issues & Workarounds

1. **405 Method Not Allowed** → Backend not running yet (deploy it!)
2. **CORS errors** → Backend CORS is configured for S3 origin, should work once backend is up
3. **401 Unauthorized** → Need to login first
4. **Connection timeout** → Check backend is running and security groups allow port 8080

### Security Notes

- Currently using HTTP (not HTTPS) - temporary until CloudFront is approved
- JWT secret is placeholder - should rotate in production
- Database password is in environment - consider using AWS Secrets Manager
- S3 buckets are public - will switch to CloudFront OAC when approved
