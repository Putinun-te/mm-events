# Database Schema Update - Bookings Table

## What Changed

The `database-setup.sql` file has been updated to reflect the new bookings table structure that supports JSON-based events.

---

## Key Changes to Bookings Table

### ❌ Old Schema (Before)
```sql
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id INT NOT NULL,                    -- ❌ INT with FK to events table
    quantity INT NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    booking_date DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE  -- ❌ FK constraint
);
```

### ✅ New Schema (After)
```sql
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id VARCHAR(255) NOT NULL,           -- ✅ VARCHAR for JSON event IDs
    event_title VARCHAR(500),                  -- ✅ NEW: Store event title
    event_location VARCHAR(500),               -- ✅ NEW: Store event location
    event_start_date DATETIME,                 -- ✅ NEW: Store event date
    quantity INT NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    booking_date DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    -- ✅ NO foreign key to events table (events are in JSON)
    INDEX idx_user_id (user_id),
    INDEX idx_event_id (event_id),
    INDEX idx_status (status),
    INDEX idx_booking_date (booking_date)
);
```

---

## Why These Changes?

### Problem
- Events are stored in **JSON file** (`main_frontend/concert1/data/events.json`)
- Old bookings table tried to reference events via **foreign key** to MySQL events table
- This caused **"Event not found" errors** when booking

### Solution
- Store event details **directly in bookings table** (denormalized)
- `event_id` is now **VARCHAR** to match JSON event IDs (timestamps like "1760350889162")
- Added **event_title**, **event_location**, **event_start_date** columns
- **No foreign key** constraint to events table

### Benefits
1. ✅ Bookings work even if event doesn't exist in MySQL
2. ✅ Event details preserved even if event deleted from JSON
3. ✅ Faster queries (no JOIN needed)
4. ✅ Independent data sources (JSON events + MySQL bookings)

---

## Migration Guide

### If Starting Fresh
Just run the updated `database-setup.sql`:
```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password < database-setup.sql
```

### If Database Already Exists
The database has already been updated manually. To verify:
```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "DESCRIBE bookings;"
```

Should show:
```
+-----------------+--------------+------+-----+---------+----------------+
| Field           | Type         | Null | Key | Default | Extra          |
+-----------------+--------------+------+-----+---------+----------------+
| id              | bigint       | NO   | PRI | NULL    | auto_increment |
| user_id         | int          | NO   | MUL | NULL    |                |
| event_id        | varchar(255) | NO   | MUL | NULL    |                |
| event_title     | varchar(500) | YES  |     | NULL    |                |
| event_location  | varchar(500) | YES  |     | NULL    |                |
| event_start_date| datetime     | YES  |     | NULL    |                |
| quantity        | int          | NO   |     | NULL    |                |
| total_price     | decimal(10,2)| NO   |     | NULL    |                |
| status          | varchar(50)  | NO   | MUL | PENDING |                |
| booking_date    | datetime     | NO   | MUL | NULL    |                |
| created_at      | timestamp    | NO   |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
+-----------------+--------------+------+-----+---------+----------------+
```

---

## Data Flow

### Event Creation
1. User creates event via frontend
2. Saved to `data/events.json` with auto-generated ID (timestamp)
3. No entry in MySQL events table

### Booking Creation
1. User books tickets on event detail page
2. Frontend sends:
   - `eventId`: String (from JSON event)
   - `eventTitle`: String (from JSON event)
   - `eventLocation`: String (from JSON event)
   - `eventStartDate`: DateTime (from JSON event)
   - `quantity`: Int
   - `ticketPrice`: Double
3. Backend creates booking in MySQL with all event details
4. No need to look up event in database

### Booking Display
1. Query bookings table: `SELECT * FROM bookings WHERE user_id = ?`
2. All event info available in booking row
3. No JOIN to events table needed

---

## Testing

### Verify Schema
```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "SHOW CREATE TABLE bookings\G"
```

### Test Booking
1. Book a ticket via UI
2. Check database:
```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "SELECT id, event_id, event_title, event_location, quantity, status FROM bookings;"
```

Should see event details stored in booking.

---

## Summary

✅ **SQL script updated** to match new booking system architecture  
✅ **Bookings table** now stores event data directly  
✅ **No foreign key** to events table (events are in JSON)  
✅ **Database already migrated** and working  
✅ **Future setups** will use correct schema from the start

The `database-setup.sql` file is now **synchronized** with the current running database schema! 🎉
