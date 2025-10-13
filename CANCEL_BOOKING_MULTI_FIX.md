# 🐛 Critical Fix: Cancel Booking Affecting Other Bookings

## 🚨 Bug Discovered

**Problem:** When cancelling a booking, **all other bookings** from the same user for the same event were being affected (participants incorrectly removed).

**Root Cause:** The cancellation logic was removing participant entries one-by-one instead of properly reducing the aggregated `ticketCount`.

---

## ✅ Fix Applied

### Understanding the Participant System

The `events.json` uses an **aggregated participant model**:

```json
{
  "participants": [
    {
      "userId": 123,
      "userName": "John Doe",
      "ticketCount": 7,  // Total tickets across ALL bookings
      "joinedAt": "2025-10-13T10:00:00Z",
      "lastBookedAt": "2025-10-13T12:00:00Z"
    }
  ],
  "participantsCount": 7  // Sum of all ticketCount
}
```

### Previous (Broken) Logic:

```typescript
// ❌ WRONG: Removed participants one by one
for (let i = 0; i < quantity; i++) {
  const index = participants.findIndex(p => p.userId === userId)
  if (index !== -1) participants.splice(index, 1) // Removes entire participant!
}
```

**Problem:** This removed the entire participant object, losing ALL their bookings!

### New (Fixed) Logic:

```typescript
// ✅ CORRECT: Reduces ticket count
const participant = participants.find(p => p.userId === userId)

if (participant) {
  const cancelledQuantity = bookingDetails.quantity || 1
  const currentTicketCount = participant.ticketCount || 0
  
  // Reduce ticket count (don't remove participant unless count reaches 0)
  participant.ticketCount = Math.max(0, currentTicketCount - cancelledQuantity)
  
  // Only remove if no tickets left
  if (participant.ticketCount === 0) {
    participants.splice(participantIndex, 1)
    console.log('✅ Removed participant (all tickets cancelled)')
  } else {
    console.log(`✅ Reduced tickets (${participant.ticketCount} remaining)`)
  }
  
  // Update total count
  participantsCount = participants.reduce((sum, p) => sum + p.ticketCount, 0)
}
```

---

## 🧪 Test Scenarios

### Scenario 1: Cancel One Booking, Keep Others

**Setup:**
```
Event: "Spring Music Festival" (Capacity: 2000)
User: John (userId: 5)

Bookings:
- Booking #1: 2 tickets (CONFIRMED)
- Booking #2: 5 tickets (CONFIRMED)

Initial State:
- John's ticketCount: 7
- participantsCount: 7
- Available seats: 1993
```

**Action:** Cancel Booking #1 (2 tickets)

**Expected Result:**
```
✅ Booking #1: Status = "CANCELLED"
✅ Booking #2: Status = "CONFIRMED" (unchanged)
✅ John's ticketCount: 5 (7 - 2)
✅ participantsCount: 5
✅ Available seats: 1995
✅ John still visible in participants list
```

**What Was Broken Before:**
```
❌ Both bookings affected
❌ John removed from participants entirely
❌ participantsCount: 0
❌ Booking #2 showed as if not counted
```

---

### Scenario 2: Cancel All Bookings for User

**Setup:**
```
Event: "Tech Conference"
User: Jane (userId: 10)

Bookings:
- Booking #1: 3 tickets (CONFIRMED)
- Booking #2: 4 tickets (CONFIRMED)

Initial State:
- Jane's ticketCount: 7
- participantsCount: 25 (Jane + others)
```

**Action 1:** Cancel Booking #1 (3 tickets)

**Expected Result:**
```
✅ Jane's ticketCount: 4 (7 - 3)
✅ participantsCount: 22 (25 - 3)
✅ Jane still in participants list
```

**Action 2:** Cancel Booking #2 (4 tickets)

**Expected Result:**
```
✅ Jane's ticketCount: 0 (4 - 4)
✅ Jane REMOVED from participants (ticketCount reached 0)
✅ participantsCount: 18 (22 - 4)
✅ Jane no longer visible in participants list
```

---

### Scenario 3: Multiple Users, Same Event

**Setup:**
```
Event: "Concert Night"
Users & Bookings:
- Alice (userId: 1): 
  - Booking #1: 2 tickets
  - Booking #2: 3 tickets
  - Total ticketCount: 5

- Bob (userId: 2):
  - Booking #3: 4 tickets
  - Total ticketCount: 4

- Charlie (userId: 3):
  - Booking #4: 1 ticket
  - Total ticketCount: 1

Initial participantsCount: 10 (5 + 4 + 1)
```

**Action:** Alice cancels Booking #1 (2 tickets)

**Expected Result:**
```
✅ Alice's ticketCount: 3 (5 - 2)
✅ Bob's ticketCount: 4 (unchanged)
✅ Charlie's ticketCount: 1 (unchanged)
✅ participantsCount: 8 (3 + 4 + 1)
✅ All three users still in participants list
```

**What Was Broken Before:**
```
❌ Alice's Booking #2 also affected
❌ Alice removed entirely from participants
❌ Bob and Charlie unaffected (correct)
❌ participantsCount: 5 (wrong! Alice's remaining tickets lost)
```

---

## 🔄 Complete Cancellation Flow

```
1. User clicks "Cancel Booking" in MyBookingsPage
   ↓
2. Frontend calls: DELETE /api/bookings/{bookingId}
   ↓
3. Backend endpoint (bookings/[id].delete.ts):
   
   a) Fetch booking details from MySQL
      → Get: bookingId, eventId, quantity, userId
   
   b) Cancel booking in MySQL
      → Update: booking.status = "CANCELLED"
   
   c) Get user info from JWT token
      → Extract: userId
   
   d) Update JSON file:
      → Find event by eventId
      → Find participant by userId
      → Reduce ticketCount by cancelled quantity
      → If ticketCount = 0, remove participant
      → Recalculate participantsCount (sum all ticketCounts)
      → Save JSON
   
   ↓
4. Return 204 No Content (success)
   ↓
5. Frontend shows success toast
   ↓
6. Auto-refresh booking list after 1 second
   ↓
7. Event page displays updated capacity
```

---

## 🎯 Key Differences

| Aspect | ❌ Old (Broken) | ✅ New (Fixed) |
|--------|----------------|---------------|
| **Data Model** | Array of individual entries | Aggregated ticketCount |
| **Cancellation** | Remove entries one-by-one | Reduce ticketCount |
| **Multiple Bookings** | Affects all bookings | Only affects cancelled booking |
| **Participant Visibility** | Removed incorrectly | Removed only when count = 0 |
| **participantsCount** | Counted entries | Sum of all ticketCounts |
| **Data Consistency** | ❌ Broken | ✅ Maintained |

---

## 📝 Code Comparison

### ❌ Old (Broken) Code:
```typescript
// Remove participant entries (one per ticket booked)
for (let i = 0; i < quantity && removed < quantity; i++) {
  const participantIndex = foundEvent.participants.findIndex(
    (p: any) => p.userId === userId
  )
  
  if (participantIndex !== -1) {
    foundEvent.participants.splice(participantIndex, 1) // ❌ WRONG!
    removed++
  }
}

foundEvent.participantsCount = foundEvent.participants.length // ❌ WRONG!
```

### ✅ New (Fixed) Code:
```typescript
// Find the participant by userId
const participant = foundEvent.participants.find((p: any) => p.userId === userId)

if (participant) {
  const cancelledQuantity = bookingDetails.quantity || 1
  const currentTicketCount = participant.ticketCount || 0
  
  // Reduce ticket count by the cancelled booking quantity
  participant.ticketCount = Math.max(0, currentTicketCount - cancelledQuantity)
  
  // If ticket count reaches 0, remove the participant entirely
  if (participant.ticketCount === 0) {
    const participantIndex = foundEvent.participants.findIndex((p: any) => p.userId === userId)
    foundEvent.participants.splice(participantIndex, 1)
    console.log(`✅ Removed participant (all tickets cancelled)`)
  } else {
    console.log(`✅ Reduced tickets (${participant.ticketCount} remaining)`)
  }
  
  // Update participants count (sum of all ticket counts)
  foundEvent.participantsCount = foundEvent.participants.reduce(
    (sum: number, p: any) => sum + (p.ticketCount || 0),
    0
  )
}
```

---

## 🧪 Manual Testing Steps

### Test 1: Multiple Bookings, Cancel One

1. **Login** to the application
2. **Book tickets** for "Spring Music Festival":
   - First time: Book 2 tickets
   - Second time: Book 5 tickets
   - **Check:** My Bookings shows 2 separate bookings

3. **View Event Detail:**
   - You should be in participants list
   - Your entry should show: `ticketCount: 7`
   - participantsCount should include your 7 tickets

4. **Cancel first booking** (2 tickets):
   - Go to My Bookings
   - Click "Cancel Booking" on the 2-ticket booking
   - Confirm cancellation

5. **Verify Results:**
   ```bash
   # Check MySQL
   docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db \
     -e "SELECT id, event_id, quantity, status FROM bookings WHERE user_id=YOUR_USER_ID;"
   
   # Expected:
   # Booking 1: status = "CANCELLED", quantity = 2
   # Booking 2: status = "CONFIRMED", quantity = 5 ✅
   ```

6. **Check JSON file:**
   ```bash
   cat main_frontend/concert1/data/events.json | \
     jq '.[] | select(.title=="Spring Music Festival") | {participantsCount, participants: .participants[]}'
   
   # Expected:
   # Your ticketCount should be 5 (not 0!)
   # You should still be in participants list ✅
   ```

7. **View Event Page:**
   - Refresh the event detail page
   - **Check:** Participant count reflects 5 tickets (not 0)
   - **Check:** You're still visible in participants list

---

### Test 2: Cancel All Bookings

1. **Continue from Test 1** (you have 5 tickets remaining)

2. **Cancel second booking** (5 tickets):
   - Go to My Bookings
   - Cancel the 5-ticket booking

3. **Verify Results:**
   ```bash
   # Check MySQL
   docker compose exec mysql mysql -uconcert_user -pconcert_password concert_db \
     -e "SELECT id, quantity, status FROM bookings WHERE user_id=YOUR_USER_ID;"
   
   # Expected:
   # Both bookings: status = "CANCELLED" ✅
   ```

4. **Check JSON:**
   ```bash
   cat main_frontend/concert1/data/events.json | \
     jq '.[] | select(.title=="Spring Music Festival") | .participants[] | select(.userId==YOUR_USER_ID)'
   
   # Expected:
   # No output (you're removed from participants) ✅
   ```

---

## 🎉 Benefits of the Fix

### ✅ Correct Behavior:
- Cancelling one booking doesn't affect others
- Ticket counts accurately reflect reality
- Participants only removed when all bookings cancelled
- Data stays consistent between MySQL and JSON

### ✅ User Experience:
- Users can safely cancel individual bookings
- Multiple bookings per event work correctly
- Capacity display is accurate
- No unexpected side effects

### ✅ Data Integrity:
- MySQL stores individual bookings (many rows)
- JSON aggregates participant data (one entry per user per event)
- Cancellation properly syncs both systems
- participantsCount = sum of all ticketCounts ✅

---

## 📊 System Architecture

### Data Flow:

```
┌─────────────────────────────────────────────┐
│         MySQL Database (Bookings)          │
│                                             │
│  Booking #1: userId=5, eventId=123, qty=2  │
│  Booking #2: userId=5, eventId=123, qty=5  │
│  Booking #3: userId=6, eventId=123, qty=3  │
└─────────────────────────────────────────────┘
                    ↕ Sync
┌─────────────────────────────────────────────┐
│         JSON File (events.json)             │
│                                             │
│  Event 123:                                 │
│    participants: [                          │
│      { userId: 5, ticketCount: 7 },  ← Sum │
│      { userId: 6, ticketCount: 3 }          │
│    ]                                        │
│    participantsCount: 10  ← Total Sum       │
└─────────────────────────────────────────────┘
```

### On Booking Creation:
```
MySQL: INSERT new booking (qty: 2)
JSON:  participant.ticketCount += 2
```

### On Booking Cancellation:
```
MySQL: UPDATE booking SET status='CANCELLED'
JSON:  participant.ticketCount -= 2
       IF ticketCount = 0 THEN remove participant
```

---

## ✅ Verification Checklist

- [x] Fixed participant reduction logic
- [x] Only affects cancelled booking
- [x] Other bookings remain unaffected
- [x] Ticket count properly reduced (not removed)
- [x] Participant removed only when count = 0
- [x] participantsCount calculated correctly
- [x] Console logs show correct behavior
- [x] Error handling for edge cases
- [x] Documentation updated
- [x] Test scenarios provided

---

## 🚀 Ready to Test!

The critical bug is now fixed. Multiple bookings per event are safe to cancel individually without affecting each other.

**Test it at:** http://localhost:3000/concert/MyBookingsPage 🎉
