# 🚀 Quick Start Guide - Your Event Platform

## ✅ System Status: READY TO USE!

### What You Have
1. ✅ **Account System** - Saves to MySQL database
2. ✅ **Event System** - Saves to JSON file  
3. ✅ **Booking System** - Full ticket booking
4. ✅ **Docker Environment** - Everything containerized

---

## 🎯 Quick Access

### Open Your App
```
http://localhost:3000/concert/
```

### Check Docker Status
```bash
docker compose ps
```

Should show:
- ✅ concert-mysql (healthy)
- ✅ concert-backend (running)
- ✅ concert-frontend (running)

---

## 📝 Quick Actions

### 1. View Your Event
1. Open: `http://localhost:3000/concert/ProductPage`
2. You'll see event: **"dasda"** (your test event)
3. Click it to see details

### 2. Create New Event
1. Login if not logged in
2. Go to: Create Event page
3. Fill the form:
   - Title: "My Concert"
   - Description: "Amazing show"
   - Date/Time: Pick future dates
   - Person Limit: 100
4. Click "Create Event"
5. ✅ Saved to JSON!

### 3. Edit Your Profile
1. Go to Account page
2. Update: Name, Phone, Address, etc.
3. Click "Save Changes"
4. ✅ Saved to database!

### 4. Book Tickets
1. Go to Product Page
2. Click any event
3. Select quantity
4. Click "Book Now"
5. ✅ Booking created!

---

## 🔍 Verify Everything Works

### Check Events JSON
```bash
docker compose exec frontend cat /app/data/events.json
```

### Check Database
```bash
docker compose exec mysql mysql -u concert_user -pconcert_password concert_db -e "SELECT id, username, name, email FROM users;"
```

### View Logs
```bash
# Frontend logs
docker compose logs frontend --tail=30

# Backend logs  
docker compose logs backend --tail=30
```

---

## 🛠️ Common Commands

### Restart Services
```bash
# Restart frontend
docker compose restart frontend

# Restart backend
docker compose restart backend

# Restart all
docker compose restart
```

### Stop/Start
```bash
# Stop all
docker compose down

# Start all
docker compose up -d
```

### Rebuild
```bash
# Rebuild backend
docker compose up -d --build backend

# Rebuild frontend
docker compose up -d --build frontend
```

---

## 📊 Data Files

### Events (JSON)
- **Location**: `./main_frontend/concert1/data/events.json`
- **Current**: 1 event stored
- **Backup**: `cp data/events.json data/events-backup.json`

### Database (MySQL)
- **Container**: concert-mysql
- **Database**: concert_db
- **Tables**: users, events, bookings
- **Backup**: `docker compose exec mysql mysqldump -u concert_user -pconcert_password concert_db > backup.sql`

---

## 🎨 Features Available

### User Features
- [x] Register/Login
- [x] Edit Profile (saves to SQL)
- [x] Logout with confirmation
- [x] Dashboard with stats

### Event Features  
- [x] Create Event (saves to JSON)
- [x] Browse Events (from JSON)
- [x] Search Events
- [x] Filter by Category
- [x] Filter by Date
- [x] Event Details
- [x] My Events

### Booking Features
- [x] Book Tickets
- [x] View My Bookings
- [x] Booking Status
- [x] Toast Notifications

---

## 🐛 Troubleshooting

### Issue: Page Not Loading
```bash
# Check containers
docker compose ps

# Restart frontend
docker compose restart frontend
```

### Issue: Events Not Showing
```bash
# Check JSON file
docker compose exec frontend cat /app/data/events.json

# Should show at least your test event
```

### Issue: Can't Save Profile
```bash
# Check backend
docker compose logs backend --tail=50

# Restart backend
docker compose restart backend
```

### Issue: Frontend Errors
```bash
# View errors
docker compose logs frontend --tail=100

# Clear and restart
docker compose restart frontend
```

---

## 📈 Your First Event (Already Created!)

```json
{
  "id": 1760350889162,
  "title": "dasda",
  "description": "uasiuahuid",
  "personLimit": 1122,
  "startDate": "2025-10-13T17:21:00",
  "endDate": "2025-10-17T23:21:00",
  "userId": 22,
  "userName": "dijiojasjidai njkscjnk",
  "createdAt": "2025-10-13T10:21:29.162Z"
}
```

---

## 🎉 You're All Set!

### What Works Right Now:
✅ **Docker** - All containers running  
✅ **Events** - Save/load from JSON  
✅ **Account** - Save/load from SQL  
✅ **Bookings** - Full ticket system  
✅ **UI** - Beautiful Eventpop-like design  

### Start Using:
1. Open `http://localhost:3000/concert/`
2. Login with your account
3. Browse events, create new ones, book tickets!

**Enjoy your event platform!** 🎊
