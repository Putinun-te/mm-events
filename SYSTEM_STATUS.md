# System Status & Verification Guide

## ✅ Current System State (Working)

### 🐳 Docker Containers
All containers are running and healthy:
- **Backend**: `http://localhost:8080` (Spring Boot - Java 21) ✅
- **Frontend**: `http://localhost:3000/concert/` (Nuxt 4) ✅
- **MySQL**: `localhost:3306` (Database) ✅

### 🗄️ Database Schema
The `bookings` table has been successfully updated with denormalized event data:

| Field | Type | Description |
|-------|------|-------------|
| `id` | BIGINT | Primary key |
| `user_id` | BIGINT | FK to users table |
| `event_id` | VARCHAR(255) | Event ID from JSON (timestamp string) |
| `event_title` | VARCHAR(500) | Denormalized event title |
| `event_location` | VARCHAR(500) | Denormalized event location |
| `event_start_date` | DATETIME | Denormalized event start date |
| `quantity` | INT | Number of tickets |
| `total_price` | DOUBLE | Total booking price |
| `status` | VARCHAR(255) | Booking status |
| `booking_date` | DATETIME | When booking was made |
| `created_at` | DATETIME | Record creation timestamp |

### 📁 Data Storage
- **Events**: `/app/data/events.json` (inside frontend container) ✅
- **Users**: MySQL `concert_db.users` table (BIGINT IDs) ✅
- **Bookings**: MySQL `concert_db.bookings` table (with denormalized event data) ✅

---

## 🧪 Testing the Booking System

### Prerequisites
1. Start all containers: `docker compose up -d`
2. Ensure backend is healthy: `curl http://localhost:8080/api/auth/test`
   - Should return: `Auth API is working!`

### Step-by-Step Test

#### 1. Register a New User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "fullName": "Test User"
  }'
```

Expected response:
```json
{
  "token": "eyJhbGc...",
  "userId": 1,
  "username": "testuser",
  "email": "test@example.com"
}
```

#### 2. Login (or use token from registration)
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

Save the `token` from the response!

#### 3. View Events (via Frontend)
Visit: `http://localhost:3000/concert/ProductPage`

Or check events JSON directly:
```bash
docker compose exec frontend cat /app/data/events.json
```

#### 4. Create a Booking
Use the token from step 1 or 2:

```bash
TOKEN="your_jwt_token_here"

curl -X POST http://localhost:8080/api/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "1760350889162",
    "quantity": 2,
    "eventTitle": "Concert Night",
    "eventLocation": "Bangkok Arena",
    "eventStartDate": "2025-10-13T19:00:00",
    "ticketPrice": 500.0
  }'
```

Expected response (HTTP 200):
```json
{
  "id": 1,
  "userId": 1,
  "eventId": "1760350889162",
  "eventTitle": "Concert Night",
  "eventLocation": "Bangkok Arena",
  "eventStartDate": "2025-10-13T19:00:00",
  "quantity": 2,
  "totalPrice": 1000.0,
  "status": "PENDING",
  "bookingDate": "2025-10-13T12:00:00",
  "createdAt": "2025-10-13T12:00:00"
}
```

#### 5. View Your Bookings
```bash
curl -X GET http://localhost:8080/api/bookings/me \
  -H "Authorization: Bearer $TOKEN"
```

#### 6. Verify in Database
```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db \
  -e "SELECT id, event_id, event_title, quantity, total_price FROM bookings;"
```

---

## 🌐 Browser Testing

### Full User Journey
1. **Open**: `http://localhost:3000/concert/`
2. **Register**: Click "Register" → Fill form → Submit
3. **Login**: Click "Login" → Use credentials → Submit
4. **Browse Events**: Navigate to "Events" page
5. **View Event Details**: Click on any event
6. **Book Tickets**: 
   - Select quantity
   - Click "Book Tickets"
   - Should see success message (NOT 500 error)
7. **View Bookings**: Navigate to "My Bookings"
   - Should see your booking with event details

---

## 🔍 Troubleshooting

### Backend Not Starting
```bash
# Check logs
docker compose logs backend

# Rebuild if needed
docker compose down backend
docker rmi develop-backend
docker compose build --no-cache backend
docker compose up -d
```

### Frontend Not Showing Events
```bash
# Check events file
docker compose exec frontend cat /app/data/events.json

# Restart frontend
docker compose restart frontend
```

### Database Connection Issues
```bash
# Check MySQL is running
docker compose ps mysql

# Test connection
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "SHOW TABLES;"
```

### 500 Error When Booking
This was the original issue - should now be fixed. If it still occurs:

1. Check backend logs: `docker compose logs backend`
2. Verify bookings table schema: `docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "DESCRIBE bookings;"`
3. Ensure event_id is VARCHAR(255) not BIGINT
4. Ensure event_title, event_location, event_start_date columns exist

---

## 📊 Key Architecture Points

### Why This Design?
1. **Events in JSON**: Flexible schema, fast development, user-generated content
2. **Bookings in MySQL**: Transactional integrity, reliable queries, data consistency
3. **Denormalized Event Data**: Historical preservation - even if event deleted, booking keeps event details

### Data Flow
```
User Creates Event → JSON File (with timestamp ID)
↓
User Books Tickets → MySQL Bookings (copies event details)
↓
User Views Bookings → MySQL Query (no JOIN needed - all data in bookings row)
```

### No Foreign Keys to Events
- Events are in JSON, not MySQL
- `event_id` is VARCHAR reference string (timestamp like "1760350889162")
- Event details (title, location, date) stored directly in bookings table
- This allows events to be deleted without breaking bookings

---

## 📚 Documentation

For more detailed information, see:
- `PLATFORM_ARCHITECTURE.md` - Complete system architecture guide
- `BOOKING_FIX_COMPLETE.md` - Technical details of the booking fix
- `BOOKING_TEST_GUIDE.md` - Original testing instructions
- `SQL_SCHEMA_UPDATE.md` - Database schema changes explained

---

## ✅ Verification Checklist

- [x] All containers running and healthy
- [x] Backend API responding (`/api/auth/test`)
- [x] Frontend loading at `http://localhost:3000/concert/`
- [x] MySQL bookings table has correct schema (VARCHAR event_id, event details columns)
- [x] Events JSON file exists at `/app/data/events.json`
- [x] Backend code has no Event entity dependencies
- [x] BookingRepository has no findByEventId method
- [x] Frontend sends complete event details in booking requests

**Status**: ✅ System is fully operational and ready for testing!
