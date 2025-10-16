# Manual Testing Guide: Participant Cancellation Feature

## 🎯 What We Fixed

When users cancel their bookings, the system now correctly reduces the `participantsCount` by the number of tickets they booked, not just by 1.

## 📊 Current Test Data

**Event:** aaaa (ID: 1760360780023)
- **Total Tickets Booked:** 71 / 2000
- **Spots Remaining:** 1929

**Participants:**
1. dijiojasjidai njkscjnk (User 22) → **1 ticket**
2. jkahjdajkdashjkdhjkasdhjka (User 23) → **1 ticket**
3. Yeen (User 25) → **57 tickets** ⭐
4. Yeen (User 26) → **12 tickets**

## 🧪 How to Test Manually

### Step 1: Open the Application
1. Navigate to: http://localhost:3000/concert
2. Login with any user account

### Step 2: View Event Participants
1. Go to the event detail page (e.g., event ID 1760360780023)
2. Scroll down to see the **Participants** section
3. Note the current count: **"66 / 2000"** or similar

### Step 3: Go to My Bookings
1. Click on "My Bookings" in the navigation
2. Find a booking for the event you're testing
3. Click "Cancel Booking"
4. Confirm the cancellation

### Step 4: Verify the Change
1. Go back to the event detail page
2. Check the **Participants** section
3. The count should have **reduced by the number of tickets**, not just by 1

## 🔍 Expected Results

### Before Cancellation:
```
Participants: 71 / 2000
- User 22: 1 ticket
- User 23: 1 ticket
- User 25: 57 tickets ← This user will cancel
- User 26: 12 tickets
```

### After User 25 Cancels (57 tickets):
```
Participants: 14 / 2000  ✅ Reduced by 57
- User 22: 1 ticket
- User 23: 1 ticket
- User 26: 12 tickets
Total: 1 + 1 + 12 = 14 ✅
```

### ❌ OLD (Broken) Behavior:
```
Participants: 70 / 2000  ❌ Only reduced by 1
```

## 🔧 Technical Changes Made

### 1. `MyBookingsPage.vue` - Added Participant Removal
```typescript
// Step 1: Cancel the booking in the database
await $fetch(`/api/bookings/${bookingId}`, {
  method: 'DELETE',
  headers: { Authorization: `Bearer ${token}` }
})

// Step 2: Remove user from event participants list
if (eventId) {
  await $fetch(`/api/events/json/${eventId}/leave`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` }
  })
}
```

### 2. `leave.post.ts` - Fixed Count Calculation
```typescript
// ❌ OLD (Wrong):
foundEvent.participantsCount = foundEvent.participants.length

// ✅ NEW (Correct):
foundEvent.participantsCount = foundEvent.participants.reduce(
  (sum: number, p: any) => sum + (p.ticketCount || 0), 
  0
)
```

## 🎬 Quick Test via Browser

1. **Login**: http://localhost:3000/concert/LoginPage
2. **My Bookings**: http://localhost:3000/concert/MyBookingsPage
3. **Cancel a booking** with multiple tickets
4. **View Event**: http://localhost:3000/concert/ProductPageDetail/[eventId]
5. **Verify count decreased** by ticket quantity, not by 1

## ✅ Success Criteria

- [ ] Participant count decreases by **ticket quantity**
- [ ] User is removed from participants list
- [ ] Progress bar updates correctly
- [ ] "Spots remaining" increases by ticket quantity
- [ ] No errors in console

## 📝 Notes

- The fix is already deployed to branch `develop/new-bb`
- Both servers are running:
  - Backend: http://localhost:8080
  - Frontend: http://localhost:3000
- You can test with any user account that has bookings

---

**Status**: ✅ Ready for testing
**Branch**: `develop/new-bb`
**Commits**: 
- db1df1c: feat: Remove user from participants list when cancelling booking
- 679c0de: fix: Correctly reduce participantsCount when user cancels booking
