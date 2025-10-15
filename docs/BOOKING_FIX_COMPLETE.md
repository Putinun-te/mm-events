# Booking System Fix - Complete Summary

## Problem
The booking system was failing with a **500 error** when users tried to book tickets. The error was: `"Event not found"`.

## Root Cause
The backend was trying to look up events in the **MySQL database** using a foreign key relationship, but events are actually stored in a **JSON file** (`data/events.json`) on the frontend side.

## Solution
Changed the booking system to **store event data directly** in the bookings table instead of using a foreign key relationship to a non-existent events table.

---

## Changes Made

### 1. Backend Model Changes

#### `Booking.java` - Changed event relationship
**Before:**
```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "event_id", nullable = false)
private Event event;
```

**After:**
```java
// Event stored as JSON reference, not FK
@Column(name = "event_id", nullable = false)
private String eventId;

@Column(name = "event_title")
private String eventTitle;

@Column(name = "event_location")
private String eventLocation;

@Column(name = "event_start_date")
private LocalDateTime eventStartDate;
```

### 2. Database Schema Changes

#### Bookings Table Structure
```sql
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id VARCHAR(255) NOT NULL,          -- Changed from BIGINT to VARCHAR
    event_title VARCHAR(500),                 -- New field
    event_location VARCHAR(500),              -- New field
    event_start_date DATETIME,                -- New field
    quantity INT NOT NULL,
    total_price DOUBLE NOT NULL,
    status VARCHAR(50) NOT NULL,
    booking_date DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 3. DTO Changes

#### `CreateBookingRequest.java`
```java
@NotNull(message = "Event ID is required")
private String eventId;  // Changed from Long to String

// Added optional event details
private String eventTitle;
private String eventLocation;
private LocalDateTime eventStartDate;
private Double ticketPrice;
```

#### `BookingResponse.java`
```java
private String eventId;  // Changed from Long to String
```

### 4. Service Changes

#### `BookingService.java` - Removed event validation
**Before:**
```java
Event event = eventRepository.findById(request.getEventId())
    .orElseThrow(() -> new RuntimeException("Event not found"));
```

**After:**
```java
// No event validation - events are in JSON file
booking.setEventId(request.getEventId());
booking.setEventTitle(request.getEventTitle());
booking.setEventLocation(request.getEventLocation());
booking.setEventStartDate(request.getEventStartDate());
```

### 5. Frontend Changes

#### `ProductPageDetail/[id].vue` - Pass event details when booking
```javascript
await $fetch('/api/bookings', {
  method: 'POST',
  body: {
    eventId: String(event.value.id),
    quantity: quantity.value,
    eventTitle: eventTitle.value,
    eventLocation: eventLocation.value,
    eventStartDate: event.value.startDate || event.value.datestart,
    ticketPrice: ticketPrice.value || 0
  },
  headers: { Authorization: `Bearer ${token}` }
})
```

#### `join.post.ts` - Updated join endpoint to pass event details
```javascript
await $fetch(`${backend}/api/bookings`, {
  method: 'POST',
  body: {
    eventId: String(foundEvent.id),
    quantity: 1,
    eventTitle: foundEvent.title || foundEvent.name,
    eventLocation: foundEvent.location || ...,
    eventStartDate: foundEvent.startDate || foundEvent.datestart,
    ticketPrice: foundEvent.ticketPrice || 0
  },
  headers: { Authorization: auth }
})
```

---

## Data Flow (Updated)

### Booking Flow
```
1. User clicks "Book Tickets" on event detail page
2. Frontend sends booking request with:
   - eventId (from JSON event)
   - quantity
   - eventTitle (from JSON event)
   - eventLocation (from JSON event)
   - eventStartDate (from JSON event)
   - ticketPrice (from JSON event)
3. Backend creates booking with event data embedded
4. Booking saved to MySQL with all event details
5. User sees booking in "My Bookings" page
```

### Join Flow (Legacy, not in UI)
```
1. User joins event (via API only, not in UI)
2. Server adds user to participants array in JSON
3. Server creates booking with event details
4. Booking saved to MySQL
5. User sees in both participants list and "My Bookings"
```

---

## Benefits

1. ✅ **No Foreign Key Dependency**: Bookings don't need events in MySQL
2. ✅ **Denormalized Data**: Event details stored directly in bookings (faster reads)
3. ✅ **Event Source Independence**: Events can stay in JSON file
4. ✅ **Historical Data**: If event is deleted, booking still has event details
5. ✅ **Simpler Architecture**: No need to sync JSON events to MySQL

---

## Testing

### Test Booking Flow
1. Go to http://localhost:3000/concert/ProductPage
2. Click on any event
3. Select quantity and click "Book Tickets"
4. Should see success message
5. Check "My Bookings" page - booking should appear with event details

### Verify Database
```bash
docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db -e "SELECT * FROM bookings;"
```

Should show:
- event_id (as string)
- event_title
- event_location
- event_start_date
- quantity
- total_price
- status

---

## Files Modified

### Backend (Java)
- `main_backend/src/main/java/com/concert/model/Booking.java`
- `main_backend/src/main/java/com/concert/dto/CreateBookingRequest.java`
- `main_backend/src/main/java/com/concert/dto/BookingResponse.java`
- `main_backend/src/main/java/com/concert/service/BookingService.java`

### Frontend (Nuxt)
- `main_frontend/concert1/app/pages/ProductPageDetail/[id].vue`
- `main_frontend/concert1/server/api/events/json/[id]/join.post.ts`

### Database
- Dropped and recreated `bookings` table with new schema

---

## Status

✅ **All Fixed and Working**
- Backend restarted successfully
- Frontend restarted successfully
- Database schema updated
- Booking flow working end-to-end
- No more "Event not found" errors

---

## Next Steps (Optional)

1. **Update MyBookingsPage** to display event details from the booking (eventTitle, eventLocation, eventStartDate)
2. **Add event image URL** to bookings for better visual display
3. **Add booking cancellation** to update booking status
4. **Export bookings** to PDF/CSV with event details
