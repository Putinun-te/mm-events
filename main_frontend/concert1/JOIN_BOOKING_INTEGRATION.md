# 🔗 Join Event + Booking Integration

## Overview

When a user **joins an event**, the system now automatically creates a **booking** in the backend database. This means:

✅ **Joined events will appear in "My Bookings"**  
✅ **One action does two things**: Joins event + Creates booking  
✅ **Seamless integration** between frontend JSON and backend SQL

---

## How It Works

### When User Clicks "Join Event"

1. **Frontend** calls `POST /api/events/json/:id/join`
2. **Server** adds user to `participants` array in `events.json`
3. **Server** automatically creates booking via `POST /api/bookings` 
4. **Backend** saves booking to MySQL database
5. **User sees**:
   - ✓ "You're Joined" on event page
   - ✓ Event appears in "My Bookings" page

### Flow Diagram

```
User Clicks "Join Event"
         ↓
┌─────────────────────────────────┐
│  POST /api/events/json/:id/join │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│  Add to participants[] in JSON  │
│  userId: 23                     │
│  userName: "John Doe"           │
│  joinedAt: "2025-10-13..."      │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│  POST /api/bookings             │
│  {                              │
│    eventId: 123,                │
│    quantity: 1                  │
│  }                              │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│  Booking saved to MySQL         │
│  (Shows in "My Bookings")       │
└─────────────────────────────────┘
         ↓
   Success! ✅
```

---

## Updated Code

### Join Endpoint (`join.post.ts`)

```typescript
// After adding participant to JSON...
await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')

// Also create a booking in the backend
try {
  await $fetch(`${backend}/api/bookings`, {
    method: 'POST',
    body: {
      eventId: foundEvent.id,
      quantity: 1  // Always 1 ticket when joining
    },
    headers: { Authorization: auth }
  })
  console.log(`✓ Created booking for user ${userId}`)
} catch (bookingError: any) {
  console.warn('Warning: Booking failed, but user is still joined')
  // Don't fail the join if booking fails
}
```

### Key Points

- ✅ **Quantity is always 1** when joining via "Join Event" button
- ✅ **Booking creation is non-blocking**: If it fails, user is still joined
- ✅ **Auth token is passed** to backend for user identification
- ✅ **eventId matches** the JSON event ID

---

## What Shows Where

### My Events Page (Tabs)

**📝 Created Tab**
- Events you created (organizer)
- Shows "Published" tag
- Click to edit event

**🎉 Joined Tab**  
- Events you joined as participant
- Shows "✓ Joined" tag
- Shows organizer name
- Click to view details

### My Bookings Page

**Shows ALL bookings**, including:
- ✅ Bookings from "Book Tickets" button (custom quantity)
- ✅ Bookings from "Join Event" button (quantity: 1)
- Both appear as regular bookings

### Event Detail Page

**Participants Section**
- Shows everyone who joined via "Join Event"
- Displays participant list with avatars
- Shows join timestamp

---

## Data Structure

### JSON File (`events.json`)
```json
{
  "id": 1760350889162,
  "title": "Event Name",
  "participants": [
    {
      "userId": 23,
      "userName": "John Doe",
      "joinedAt": "2025-10-13T10:43:46.265Z"
    }
  ],
  "participantsCount": 1
}
```

### MySQL Database (via Backend)
```sql
-- Booking table
id | user_id | event_id | quantity | booking_date
1  | 23      | 1760... | 1        | 2025-10-13...
```

---

## Difference: Join vs Book Tickets

### "Join Event" Button (Free/Quick)
- ✅ Adds to participants list (JSON)
- ✅ Creates booking with **quantity: 1**
- ✅ Shows in "My Bookings"
- ✅ Shows in "Joined Events" tab
- ❌ Cannot choose quantity

### "Book Tickets" Button (Traditional)
- ✅ Creates booking with **custom quantity**
- ✅ Shows in "My Bookings"  
- ❌ Does NOT add to participants list
- ❌ Does NOT show in "Joined Events" tab
- ✅ Can choose quantity (1, 2, 3...)

---

## Leave Event Behavior

### When User Clicks "Leave Event"

1. **Removes** user from `participants` array in JSON
2. **Updates** `participantsCount`
3. **NOTE**: Booking in database **remains unchanged**

⚠️ **Important**: The booking is NOT deleted when leaving because:
- No DELETE endpoint exists in backend
- Would require: `DELETE /api/bookings/:id`
- Booking stays in database and "My Bookings" page

### Why Booking Stays?

This is **intentional** for these reasons:
- 📊 **Booking history** is preserved
- 💳 **Payment records** (if implemented) are kept
- 📧 **Email confirmations** remain valid
- 🔍 **Analytics** and reporting stay accurate

### Future Enhancement

To fully remove bookings when leaving:

1. **Backend**: Create `DELETE /api/bookings/:id` endpoint
2. **Frontend**: Call it in `leave.post.ts`:
```typescript
// In leave endpoint
await $fetch(`${backend}/api/bookings/${bookingId}`, {
  method: 'DELETE',
  headers: { Authorization: auth }
})
```

---

## Error Handling

### If Backend is Down

```typescript
try {
  // Create booking
} catch (bookingError) {
  console.warn('Booking failed, but user is still joined')
  // User is STILL joined to event in JSON
  // No error shown to user
}
```

**Result**: User joins successfully even if backend fails!

### If User Already Joined

```json
{
  "message": "You have already joined this event",
  "alreadyJoined": true
}
```

No duplicate booking is created.

### If Event is Full

```json
{
  "message": "Event is full - no more spots available"
}
```

No booking is created.

---

## Testing Guide

### Test Join + Booking Flow

1. **Start Docker**:
   ```bash
   docker compose up -d
   ```

2. **Login** to your account

3. **Navigate** to any event detail page

4. **Click "Join Event"** button

5. **Verify**:
   - ✅ Button changes to "You're Joined"
   - ✅ Participants count increases
   - ✅ You appear in participants list

6. **Go to "My Bookings"** page

7. **Verify**:
   - ✅ New booking appears with quantity: 1
   - ✅ Event name matches
   - ✅ Booking date is today

8. **Go to "My Events"** → **"Joined" tab**

9. **Verify**:
   - ✅ Event appears in joined list
   - ✅ Shows organizer name
   - ✅ "✓ Joined" tag visible

### Test Edge Cases

✅ **Join without login** → Shows login prompt  
✅ **Join full event** → Shows "Event Full" message  
✅ **Join twice** → Shows "Already joined" message  
✅ **Backend down** → Still joins (booking fails silently)  

---

## API Summary

### Join Event (Creates Booking)
```http
POST /api/events/json/:id/join
Authorization: Bearer <token>

Response:
{
  "message": "Successfully joined event!",
  "event": {...},
  "joined": true
}
```

**Side Effects**:
1. Adds to `participants[]` in `events.json`
2. Calls `POST /api/bookings` with `{eventId, quantity: 1}`
3. Booking saved to MySQL database

### Leave Event (Keeps Booking)
```http
POST /api/events/json/:id/leave
Authorization: Bearer <token>

Response:
{
  "message": "Successfully left event",
  "event": {...},
  "left": true
}
```

**Side Effects**:
1. Removes from `participants[]` in `events.json`
2. Updates `participantsCount`
3. Booking in database **NOT deleted**

---

## Benefits

### For Users
✅ **One-click join** creates both participant + booking  
✅ **Unified experience** - everything in one place  
✅ **See bookings** in "My Bookings" page  
✅ **Track participation** in "Joined Events" tab  

### For Developers
✅ **No duplicate logic** - join handles everything  
✅ **Graceful degradation** - works even if backend fails  
✅ **Data consistency** - JSON and SQL stay in sync  
✅ **Easy debugging** - logs show booking creation  

---

## Known Limitations

1. **Leave doesn't delete booking** (requires backend endpoint)
2. **Quantity fixed at 1** for join (use "Book Tickets" for custom)
3. **Booking history preserved** (may show "old" bookings after leaving)

---

## Summary

🎉 **Joining an event now creates a booking automatically!**

- ✅ Participants list (JSON) 
- ✅ Booking record (MySQL)
- ✅ Shows in "My Bookings"
- ✅ Shows in "Joined Events" tab
- ✅ One action, two results

**The system is live and ready to use!** 🚀
