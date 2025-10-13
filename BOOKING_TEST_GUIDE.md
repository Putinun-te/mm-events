# 🎯 Booking Fix - Test Guide

## ✅ What Was Fixed
- **500 Error** when booking tickets is now fixed
- Backend no longer requires events in MySQL database
- Events stay in JSON file, booking stores event details directly

---

## 🧪 How to Test

### 1. Access the Application
```
http://localhost:3000/concert/ProductPage
```

### 2. Test Booking Flow

#### Step 1: Browse Events
- Go to Product Page (Discover Events)
- You should see the list of available events
- Click on any event to view details

#### Step 2: Book Tickets
1. On event detail page, select quantity (1, 2, 3...)
2. Click **"Book Tickets"** button
3. Should see: ✅ **"Successfully booked X ticket(s)!"** message
4. Will redirect to "My Bookings" page

#### Step 3: Verify Booking
1. Check "My Bookings" page
2. Should see your booking with:
   - Event title
   - Event location
   - Event start date
   - Quantity
   - Total price
   - Status (CONFIRMED)

### 3. Verify in Database

```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "SELECT id, event_id, event_title, quantity, status FROM bookings;"
```

Expected output:
```
+----+---------------+--------------+----------+-----------+
| id | event_id      | event_title  | quantity | status    |
+----+---------------+--------------+----------+-----------+
| 1  | 1760350889162 | dasda        | 2        | CONFIRMED |
+----+---------------+--------------+----------+-----------+
```

---

## 🔍 What Changed

### Before (Broken)
```
POST /api/bookings
Body: { eventId: 123, quantity: 2 }

❌ Backend: "Event not found" (500 error)
   - Tried to find eventId in MySQL events table
   - Events table doesn't exist (events are in JSON)
```

### After (Fixed)
```
POST /api/bookings
Body: { 
  eventId: "1760350889162",
  quantity: 2,
  eventTitle: "dasda",
  eventLocation: "Bangkok",
  eventStartDate: "2025-10-13T17:21:00",
  ticketPrice: 100
}

✅ Backend: Creates booking with event details
   - No need to look up event in database
   - All event info stored in booking
```

---

## 📊 Check the Fix

### Frontend Logs
```bash
docker compose logs frontend --tail=20
```
Should show: ✅ Nuxt running on http://0.0.0.0:3000/concert/

### Backend Logs
```bash
docker compose logs backend --tail=30
```
Should show: ✅ Started ConcertBackendApplication

### All Containers Status
```bash
docker compose ps
```
Should show:
```
✅ concert-backend   - Up (healthy)
✅ concert-frontend  - Up
✅ concert-mysql     - Up (healthy)
```

---

## 🎉 Success Criteria

### ✅ Booking Works
- [x] Can click "Book Tickets" without 500 error
- [x] See success message
- [x] Booking appears in "My Bookings"
- [x] Event details show correctly

### ✅ Database Updated
- [x] bookings table has event_id as VARCHAR
- [x] bookings table has event_title, event_location, event_start_date
- [x] No foreign key to events table
- [x] Can insert bookings successfully

### ✅ System Stable
- [x] All containers running and healthy
- [x] No errors in backend logs
- [x] Frontend accessible and responsive

---

## 🐛 If Something Goes Wrong

### Issue: Still getting 500 error
**Solution:**
```bash
# Restart all containers
docker compose restart

# Check logs
docker compose logs backend --tail=50
docker compose logs frontend --tail=50
```

### Issue: Bookings not showing
**Solution:**
```bash
# Check if booking was created
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "SELECT * FROM bookings;"

# Check user is logged in (JWT token in localStorage)
# Open browser console and check: localStorage.getItem('jwt_token')
```

### Issue: Database schema wrong
**Solution:**
```bash
# Recreate bookings table
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db <<EOF
DROP TABLE IF EXISTS bookings;
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id VARCHAR(255) NOT NULL,
    event_title VARCHAR(500),
    event_location VARCHAR(500),
    event_start_date DATETIME,
    quantity INT NOT NULL,
    total_price DOUBLE NOT NULL,
    status VARCHAR(50) NOT NULL,
    booking_date DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
EOF

# Restart backend
docker compose restart backend
```

---

## 📝 Summary

**Problem:** Booking failed because backend looked for events in MySQL, but events are in JSON file

**Solution:** Store event details directly in bookings table (denormalized), no foreign key needed

**Result:** ✅ Booking works perfectly, event data preserved even if event is deleted from JSON

---

## 🚀 Ready to Use!

Your booking system is now fully functional. Users can:
1. ✅ Browse events
2. ✅ Book tickets
3. ✅ See bookings in "My Bookings"
4. ✅ View complete event details

All working without any 500 errors! 🎊
