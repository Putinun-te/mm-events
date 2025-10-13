# 👥 Participant Tracking System

## Overview
The participant tracking system allows event organizers and attendees to see who has booked tickets for events in real-time. When users book tickets, they are automatically added to the event's participant list with their ticket count and join date.

## Features

### ✅ Core Functionality
- **Automatic Tracking**: Users are automatically added to participants when booking tickets
- **Ticket Count Display**: Shows how many tickets each participant booked
- **Real-time Updates**: Participant list updates immediately after booking
- **Cumulative Tracking**: Multiple bookings from the same user increment their ticket count
- **Graceful Degradation**: Booking succeeds even if participant tracking fails

### 🎨 UI Components
- **Participant Cards**: Each participant displayed with avatar, name, and ticket count
- **Total Count Badge**: Shows total tickets booked across all participants
- **Empty State**: Friendly message when no one has joined yet
- **Scrollable List**: Handles large number of participants with max-height container
- **Gradient Design**: Purple/violet theme matching event detail page

## Architecture

### Data Flow
```
User Books Ticket
    ↓
1. POST /api/bookings (MySQL)
    ↓
2. GET /api/auth/me (fetch user profile)
    ↓
3. POST /api/events/json/[id]/add-participant (JSON)
    ↓
4. GET /api/events/json/[id] (reload event)
    ↓
Display Updated Participant List
```

### Storage Strategy
- **Dual-Write Pattern**: 
  - Bookings stored in MySQL (transactional, relational)
  - Participants stored in events.json (fast read, embedded)
- **Why Both?**: MySQL for complex queries, JSON for fast event page loads

### Data Structure
```typescript
// In events.json
{
  "id": 1760360780023,
  "title": "Summer Music Festival",
  "participants": [
    {
      "userId": 23,
      "userName": "John Doe",
      "ticketCount": 2,
      "joinedAt": "2025-10-13T13:06:20.024Z"
    }
  ],
  "participantsCount": 2  // Total tickets across all participants
}
```

## API Endpoints

### POST `/api/events/json/[id]/add-participant`
Adds or updates a participant for an event.

**Request Body:**
```json
{
  "userId": 23,
  "userName": "John Doe",
  "ticketCount": 2
}
```

**Response:**
```json
{
  "participants": [...],
  "participantsCount": 5
}
```

**Behavior:**
- If participant exists: increments their `ticketCount`
- If new participant: adds to array with current timestamp
- Automatically calculates total `participantsCount`

## Error Handling

### Graceful Degradation
The system uses **non-blocking participant tracking** to ensure bookings always succeed:

```typescript
// Step 1: Create booking (critical - must succeed)
await $fetch('/api/bookings', { ... })

// Step 2: Track participant (non-blocking - log warning if fails)
try {
  const userProfile = await $fetch('/api/auth/me', { ... })
  await $fetch(`/api/events/json/${id}/add-participant`, { ... })
} catch (error) {
  console.warn('Participant tracking failed, but booking succeeded:', error)
}

// Success toast shown regardless of participant tracking
success('Successfully booked tickets!')
```

### Failure Scenarios
| Scenario | Behavior |
|----------|----------|
| Booking API fails | ❌ Show error, no booking created |
| User profile fetch fails | ⚠️ Use fallback name "Anonymous", continue |
| Participant API fails | ⚠️ Log warning, booking still succeeds |
| Event reload fails | ⚠️ Log warning, show stale participant list |

## UI Components

### Participant List
Located in `ProductPageDetail/[id].vue` (lines ~298-345)

**Features:**
- Gradient background (violet/purple theme)
- Avatar circles with user initials
- Ticket count badges (🎫 icon)
- Join date formatting
- Hover effects on cards
- Scrollable container (`max-h-60`)

**Empty State:**
- Dashed border placeholder
- 👥 emoji icon
- "Be the first to join" message

### Visual Design
```
┌─────────────────────────────────────┐
│ 👥 Participants    [5 tickets booked]│
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [J] John Doe      🎫 2 tickets  │ │
│ │     Joined Oct 13, 2025         │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [A] Alice Smith   🎫 3 tickets  │ │
│ │     Joined Oct 12, 2025         │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Usage Example

### For Users (Booking Tickets)
1. Navigate to event detail page
2. Select ticket quantity
3. Click "Book Tickets" button
4. ✅ Success toast appears
5. See yourself added to participant list (if visible)
6. Redirected to "My Bookings" page

### For Event Organizers (Viewing Participants)
1. Create an event
2. Share event link with attendees
3. Monitor participant list on event detail page
4. See real-time updates as users book
5. Track total ticket count in badge

## Testing Checklist

### ✅ Happy Path
- [ ] Book tickets as logged-in user
- [ ] Verify participant appears in list
- [ ] Check ticket count shows correctly
- [ ] Confirm join date is current
- [ ] Test multiple bookings from same user (should increment count)

### ⚠️ Edge Cases
- [ ] Book without login → should redirect to login page
- [ ] Book with expired token → should show error
- [ ] Book when participant API is down → booking should still succeed
- [ ] Book with special characters in name → should display correctly
- [ ] View event with 100+ participants → should scroll

### 🔒 Security
- [ ] Cannot add participants to other users' bookings
- [ ] JWT token required for participant tracking
- [ ] SQL injection protection in booking creation
- [ ] File system race conditions handled in JSON writes

## Future Enhancements

### Potential Features
1. **"You" Indicator**: Highlight current user in participant list
2. **Participant Limit**: Enforce `personLimit` vs total `participantsCount`
3. **Participant Search**: Filter/search in large participant lists
4. **Participant Profiles**: Click participant to view their profile
5. **Booking History**: Show date of each booking per participant
6. **Waitlist**: Add users to waitlist when event is full
7. **Export Participants**: CSV download for event organizers
8. **Email Notifications**: Notify participants of event updates

### Technical Improvements
1. **WebSocket Updates**: Real-time participant list without reload
2. **Pagination**: Server-side pagination for large participant lists
3. **Caching**: Redis cache for participant counts
4. **Transactions**: Distributed transaction across MySQL + JSON
5. **Audit Log**: Track all participant list changes

## Troubleshooting

### Participant list not updating
**Symptoms**: Booked tickets but don't see participant
**Fixes**:
1. Check browser console for errors
2. Verify JWT token is valid (`localStorage.getItem('jwt_token')`)
3. Check `events.json` file has `participants` array
4. Ensure Docker containers are running
5. Check API endpoint returns 200 status

### Ticket count incorrect
**Symptoms**: Participant shows wrong ticket count
**Fixes**:
1. Check multiple bookings from same user are being aggregated
2. Verify `ticketCount` field in participant object
3. Look for race conditions in concurrent bookings
4. Check `participantsCount` calculation in API

### Console warnings
**Expected**: Non-blocking participant tracking may log warnings
```
⚠️ Failed to fetch user profile, using fallback: [error]
⚠️ Failed to add participant, but booking was successful: [error]
```
These are normal if participant APIs fail - booking still succeeds.

## Related Files

### Frontend
- `app/pages/ProductPageDetail/[id].vue` - Main event detail page
- `app/composables/useToast.ts` - Toast notifications

### Backend (Nuxt Server Routes)
- `server/api/bookings/index.post.ts` - Create booking (MySQL)
- `server/api/auth/me.get.ts` - Fetch user profile
- `server/api/events/json/[id]/add-participant.post.ts` - Add participant (JSON)
- `server/api/events/json/[id].get.ts` - Fetch event with participants

### Data Files
- `app/data/events.json` - Event data with participants array

## Support
If you encounter issues with participant tracking:
1. Check the browser console for errors
2. Verify Docker containers are running
3. Review the API logs in backend container
4. Test booking flow end-to-end
5. Check `events.json` file structure

---
**Last Updated**: Current session  
**Feature Status**: ✅ Implemented and ready for testing
