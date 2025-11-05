# ✅ All Endpoints - Testing Guide

## 🔐 Authentication Endpoints

### 1. Test Endpoint (Public - No Auth)
```bash
curl http://52.221.197.39:8080/api/auth/test
```
**Expected**: `"Auth API is working!"`

### 2. Register New User
```bash
curl -X POST http://52.221.197.39:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "REDACTED_PASSWORD_D!"
  }'
```
**Expected**: 
```json
{
  "token": "eyJhbGc...",
  "username": "testuser"
}
```

### 3. Login
```bash
curl -X POST http://52.221.197.39:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "REDACTED_PASSWORD_D!"
  }'
```
**Expected**:
```json
{
  "token": "eyJhbGc...",
  "username": "testuser"
}
```

### 4. Get Current User (My Account)
```bash
TOKEN="your-jwt-token-here"

curl http://52.221.197.39:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
```
**Expected**:
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com"
}
```

---

## 📅 Event Endpoints

### 5. Get All Events
```bash
curl http://52.221.197.39:8080/api/events
```
**Expected**: Array of events

### 6. Get My Events (Events I Created)
```bash
curl http://52.221.197.39:8080/api/events/me \
  -H "Authorization: Bearer $TOKEN"
```
**Expected**: Array of your events

### 7. Get Event Details
```bash
curl http://52.221.197.39:8080/api/events/1
```
**Expected**: Single event object

### 8. Create New Event
```bash
curl -X POST http://52.221.197.39:8080/api/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Concert",
    "description": "Test Description",
    "date": "2025-12-31",
    "location": "Bangkok",
    "price": 1000,
    "ticketsAvailable": 100
  }'
```

### 9. Upload Event Picture
```bash
curl -X POST http://52.221.197.39:8080/api/events/1/photo \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@path/to/image.jpg"
```

---

## 🎟️ Booking Endpoints

### 10. Get My Bookings
```bash
curl http://52.221.197.39:8080/api/bookings/me \
  -H "Authorization: Bearer $TOKEN"
```
**Expected**: Array of your bookings

### 11. Create Booking
```bash
curl -X POST http://52.221.197.39:8080/api/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": 1,
    "ticketQuantity": 2
  }'
```

### 12. Cancel Booking
```bash
curl -X DELETE http://52.221.197.39:8080/api/bookings/1 \
  -H "Authorization: Bearer $TOKEN"
```

---

## 👤 User Profile Endpoints

### 13. Update Profile
```bash
curl -X PUT http://52.221.197.39:8080/api/users/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newemail@example.com",
    "phoneNumber": "0812345678"
  }'
```

### 14. Upload Profile Photo
```bash
curl -X POST http://52.221.197.39:8080/api/users/avatar \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@path/to/avatar.jpg"
```

---

## 🌐 Frontend Pages Testing

Once backend is running, test these pages in browser:

### ✅ Authentication Pages
- **Register**: https://d3jivuimmea02r.cloudfront.net/RegisterPage
  - Fill form → Click Register
  - Should redirect to login with success message

- **Login**: https://d3jivuimmea02r.cloudfront.net/LoginPage
  - Enter credentials → Click Login
  - Should redirect to home page with user menu

### ✅ User Pages (Require Login)
- **My Account**: https://d3jivuimmea02r.cloudfront.net/AccountPage
  - Shows user profile info
  - Can edit email, phone

- **My Events**: https://d3jivuimmea02r.cloudfront.net/MyEventsPage
  - Shows events you created
  - Can edit/delete your events

- **My Bookings**: https://d3jivuimmea02r.cloudfront.net/MyBookingsPage
  - Shows tickets you booked
  - Can cancel bookings

### ✅ Event Pages
- **All Events**: https://d3jivuimmea02r.cloudfront.net/ProductPage
  - Browse all events
  - Click event to see details

- **Create Event**: https://d3jivuimmea02r.cloudfront.net/CreateEventPage
  - Fill event form
  - Upload event picture
  - Submit to create

- **Event Details**: https://d3jivuimmea02r.cloudfront.net/ProductPageDetail/1
  - Shows event info
  - Can book tickets
  - Shows organizer info

---

## 🐛 Troubleshooting

### Error: "Load failed"
**Cause**: Backend not running
**Fix**: Deploy backend using `DEPLOY_BACKEND_NOW.md`

### Error: "401 Unauthorized"
**Cause**: Invalid or expired token
**Fix**: Login again to get new token

### Error: "403 Forbidden"
**Cause**: Trying to access resource you don't own
**Fix**: Check if you're logged in as correct user

### Error: "CORS error"
**Cause**: Backend CORS not configured
**Fix**: Backend already has `@CrossOrigin(origins = "*")` - restart backend

### Error: "Network Error"
**Cause**: Backend URL incorrect
**Fix**: Check `.env` has `BACKEND_BASE_URL=http://52.221.197.39:8080`

---

## 📊 Full Flow Test

### 1. Register → Login → Create Event → Book Ticket → Check Booking

```bash
# 1. Register
curl -X POST http://52.221.197.39:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@test.com","password":"REDACTED_PASSWORD_D!"}' \
  | jq -r '.token' > /tmp/token.txt

# 2. Get token
TOKEN=$(cat /tmp/token.txt)

# 3. Check profile
curl http://52.221.197.39:8080/api/auth/me -H "Authorization: Bearer $TOKEN"

# 4. Create event
curl -X POST http://52.221.197.39:8080/api/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"My Concert",
    "description":"Test",
    "date":"2025-12-31",
    "location":"Bangkok",
    "price":500,
    "ticketsAvailable":50
  }' | jq

# 5. Get my events
curl http://52.221.197.39:8080/api/events/me -H "Authorization: Bearer $TOKEN" | jq

# 6. Book ticket (register as different user first)
# ... (create second user)

# 7. Check my bookings
curl http://52.221.197.39:8080/api/bookings/me -H "Authorization: Bearer $TOKEN" | jq
```

---

## ✅ Success Checklist

After backend deployment, verify:

- [ ] `/api/auth/test` returns "Auth API is working!"
- [ ] Can register new user
- [ ] Can login and get JWT token
- [ ] Can access `/api/auth/me` with token
- [ ] Can see all events at `/api/events`
- [ ] Can create event (with auth)
- [ ] Can see my events at `/api/events/me`
- [ ] Can book tickets
- [ ] Can see my bookings at `/api/bookings/me`
- [ ] Frontend pages load without "Load failed" error
- [ ] Can login on frontend
- [ ] Can register on frontend
- [ ] My Events page shows events
- [ ] My Bookings page shows bookings
- [ ] My Account page shows profile

---

**All endpoints are implemented and ready!** Just need to deploy backend. 🚀
