# Event Join/Leave Feature Documentation

## 🎉 Overview

The event join/leave feature allows users to participate in events without booking tickets. Users can join events to show interest and track which events they're attending.

## 📋 Features

### Backend API Endpoints

#### 1. **Join Event** - `POST /api/events/json/:id/join`
- **Authentication**: Required (JWT Bearer token)
- **Functionality**:
  - Validates user authentication
  - Checks if user already joined (prevents duplicates)
  - Checks person limit (prevents joining full events)
  - Adds participant to event with `{userId, userName, joinedAt}`
  - Updates `participantsCount`
  - Saves to `data/events.json`

**Response Examples**:
```json
// Success
{
  "message": "Successfully joined event!",
  "event": {...},
  "joined": true
}

// Already joined
{
  "message": "You have already joined this event",
  "event": {...},
  "alreadyJoined": true
}

// Event full
{
  "message": "Event is full. Cannot join."
}
```

#### 2. **Leave Event** - `POST /api/events/json/:id/leave`
- **Authentication**: Required (JWT Bearer token)
- **Functionality**:
  - Validates user authentication
  - Finds participant in participants array
  - Removes participant using splice
  - Updates `participantsCount`
  - Saves to `data/events.json`

**Response Examples**:
```json
// Success
{
  "message": "Successfully left event",
  "event": {...},
  "left": true
}

// Not joined
{
  "message": "You are not a participant of this event",
  "event": {...},
  "notJoined": true
}
```

#### 3. **Get Joined Events** - `GET /api/events/json/joined`
- **Authentication**: Required (JWT Bearer token)
- **Functionality**:
  - Gets user ID from JWT token
  - Filters events where user appears in `participants` array
  - Returns only events the user has joined

**Response**:
```json
[
  {
    "id": 123,
    "title": "Event Name",
    "participants": [...],
    "participantsCount": 5,
    ...
  }
]
```

### Frontend UI Components

#### 1. **ProductPageDetail (Event Detail Page)**

**New Features**:
- **Participants Progress Bar**: Shows capacity (e.g., "25/100 joined")
- **Join Button**: 
  - Disabled when event is full
  - Shows "Event Full" when capacity reached
  - Changes to "You're Joined" when user has joined
- **Leave Button**: 
  - Appears only when user has joined
  - Red border button next to "You're Joined"
- **Participants List**:
  - Displays all participants with avatars
  - Shows join date for each participant
  - Scrollable list for many participants

**UI States**:
```vue
<!-- Not Joined, Event Available -->
<button @click="joinEvent" :disabled="isEventFull">
  🎉 Join Event
</button>

<!-- Already Joined -->
<button disabled>✓ You're Joined</button>
<button @click="leaveEvent">Leave Event</button>

<!-- Event Full -->
<button disabled>🚫 Event Full</button>

<!-- Not Logged In -->
<div>Please login to join this event</div>
```

#### 2. **ProductCard Component**

**New Features**:
- **Participants Badge**: Shows participant count on event card
  - Purple gradient badge with 👥 icon
  - Appears in top-right of event image
  - Only shows if `participantsCount > 0`

```vue
<div v-if="participantsCount > 0" class="participants-badge">
  <span>👥</span>
  <span>{{ participantsCount }}</span>
</div>
```

#### 3. **MyEventsPage (with Tabs)**

**New Features**:
- **Tab System**:
  - **📝 Created Tab**: Shows events user created (original functionality)
  - **🎉 Joined Tab**: Shows events user joined as participant
- **Event Cards**:
  - Created events: Green "Published" tag, clickable to edit
  - Joined events: Purple "✓ Joined" tag, clickable to view details
  - Shows organizer name on joined events
  - Purple left border on joined event cards

**Tab Switching**:
```vue
<div class="tabs-container">
  <button @click="activeTab = 'created'">
    📝 Created ({{ events.length }})
  </button>
  <button @click="activeTab = 'joined'">
    🎉 Joined ({{ joinedEvents.length }})
  </button>
</div>
```

## 🗂️ Data Structure

### Event Object (in events.json)
```json
{
  "id": 1760350889162,
  "title": "Event Title",
  "description": "Event description",
  "personLimit": 100,
  "startDate": "2025-10-15T10:00:00",
  "endDate": "2025-10-15T18:00:00",
  "ticketPrice": null,
  "address": "Event location",
  "city": "City",
  "country": "Country",
  "phone": "1234567890",
  "category": "Music",
  "location": "Venue",
  "userId": 22,
  "userName": "Event Creator",
  "createdAt": "2025-01-13T10:30:00Z",
  
  // Join/Leave fields
  "participants": [
    {
      "userId": 25,
      "userName": "John Doe",
      "joinedAt": "2025-01-13T11:00:00Z"
    }
  ],
  "participantsCount": 1
}
```

### Participant Object
```typescript
{
  userId: number;      // User ID from database
  userName: string;    // User's display name
  joinedAt: string;    // ISO timestamp of when they joined
}
```

## 🔄 User Flow

### Joining an Event
1. User navigates to event detail page
2. If not logged in → Shows login prompt
3. If logged in and not joined → Shows "Join Event" button
4. User clicks "Join Event"
5. Frontend calls `POST /api/events/json/:id/join` with JWT token
6. Backend validates token, checks capacity, adds participant
7. Frontend updates UI to show "You're Joined" + "Leave Event" button
8. Participants count increases
9. User appears in participants list

### Leaving an Event
1. User is on event detail page (already joined)
2. Shows "You're Joined" (disabled) + "Leave Event" button
3. User clicks "Leave Event"
4. Frontend calls `POST /api/events/json/:id/leave` with JWT token
5. Backend removes participant from array
6. Frontend updates UI to show "Join Event" button
7. Participants count decreases
8. User removed from participants list

### Viewing Joined Events
1. User navigates to "My Events" page
2. Clicks "🎉 Joined" tab
3. Frontend calls `GET /api/events/json/joined` with JWT token
4. Backend filters events by participant userId
5. Displays joined events with organizer info
6. Click event card → Navigate to event detail page

## 🎨 Styling

### Color Scheme
- **Join/Joined**: Violet/Purple gradient (`#7C3AED`, `#A855F7`)
- **Success/Green**: Event available (`#28a745`, `#10b981`)
- **Error/Red**: Leave event (`#ef4444`)
- **Warning/Yellow**: Login required (`#f59e0b`)

### Key CSS Classes
```css
/* Participants Badge */
.participants-badge {
  background: linear-gradient(to right, #7C3AED, #A855F7);
  border-radius: 9999px;
  padding: 0.25rem 0.75rem;
  font-size: 0.75rem;
  font-weight: bold;
}

/* Join Button */
.join-button {
  background: linear-gradient(to right, #7C3AED, #A855F7);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 0.75rem;
  font-weight: 600;
}

/* Joined Tag */
.joined-tag {
  background: #7C3AED;
  color: white;
  padding: 0.25rem 0.625rem;
  border-radius: 1.25rem;
  font-size: 0.8rem;
}
```

## 🔒 Authentication

All join/leave endpoints require JWT authentication:

```typescript
const token = localStorage.getItem('jwt_token') || 
              sessionStorage.getItem('jwt_token')

await $fetch('/api/events/json/:id/join', {
  method: 'POST',
  headers: { 
    Authorization: `Bearer ${token}` 
  }
})
```

## 🐛 Error Handling

### Backend Errors
- **401 Unauthorized**: Missing or invalid JWT token
- **404 Not Found**: Event not found
- **400 Bad Request**: Event is full or invalid operation
- **500 Internal Server Error**: File system or server error

### Frontend Error Handling
```typescript
try {
  const result = await $fetch('/api/events/json/:id/join', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` }
  })
  
  if (result.joined) {
    // Success
  } else if (result.alreadyJoined) {
    // Already joined
  }
} catch (e: any) {
  const message = e?.data?.message || 'Failed to join event'
  toast(message, 'error')
}
```

## 📁 File Locations

### Backend (Server Routes)
- `server/api/events/json/[id]/join.post.ts` - Join event endpoint
- `server/api/events/json/[id]/leave.post.ts` - Leave event endpoint
- `server/api/events/json/joined.get.ts` - Get joined events endpoint

### Frontend (Pages/Components)
- `app/pages/ProductPageDetail/[id].vue` - Event detail with join/leave UI
- `app/pages/MyEventsPage.vue` - My events page with tabs
- `app/components/ProductCard.vue` - Event card with participants badge

### Data
- `data/events.json` - Event storage with participants data

## 🚀 Testing

### Manual Testing Steps

1. **Join Event**:
   - Login as user
   - Navigate to event detail page
   - Click "Join Event" button
   - Verify: Button changes to "You're Joined"
   - Verify: Participants count increases
   - Verify: User appears in participants list

2. **Leave Event**:
   - Already joined an event
   - Click "Leave Event" button
   - Verify: Button changes to "Join Event"
   - Verify: Participants count decreases
   - Verify: User removed from participants list

3. **Event Capacity**:
   - Create event with personLimit: 2
   - Join with user 1 → Success
   - Join with user 2 → Success
   - Try to join with user 3 → Shows "Event Full"

4. **Joined Events Tab**:
   - Join multiple events
   - Go to "My Events" page
   - Click "🎉 Joined" tab
   - Verify: All joined events displayed
   - Click event → Navigate to detail page

5. **Participants Badge**:
   - Go to events list (ProductPage)
   - Verify: Events with participants show badge
   - Badge shows correct count

## 🔧 Configuration

### Environment Variables
No additional environment variables needed. Uses existing:
- `BACKEND_BASE_URL` or `http://localhost:8080` for auth validation

### Docker Volume Mount
Ensure volume mount in `docker-compose.yml`:
```yaml
frontend:
  volumes:
    - ./main_frontend/concert1:/app
```

This enables:
- File sync between host and container
- `data/events.json` persistence
- Hot reload of server routes

## 📊 API Summary

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/events/json/:id/join` | POST | ✓ | Join an event |
| `/api/events/json/:id/leave` | POST | ✓ | Leave an event |
| `/api/events/json/joined` | GET | ✓ | Get joined events |
| `/api/events/json/me` | GET | ✓ | Get created events |
| `/api/events/json/:id` | GET | - | Get single event |
| `/api/events/json` | GET | - | Get all events |
| `/api/events/json` | POST | ✓ | Create event |

## ✨ Future Enhancements

Potential features to add:
- [ ] Email notifications when someone joins your event
- [ ] Join request approval (private events)
- [ ] Participant limit warnings (e.g., "Only 5 spots left!")
- [ ] Participant roles (organizer, co-host, participant)
- [ ] Export participants list (CSV, PDF)
- [ ] Check-in system for event day
- [ ] Participant chat/discussion
- [ ] Event reminders for joined events
- [ ] Social sharing ("I'm attending...")
- [ ] Waiting list when event is full

## 🎯 Key Takeaways

1. ✅ **Fully Functional**: Join/leave system is complete and working
2. ✅ **Persistent Storage**: All participant data saved to `data/events.json`
3. ✅ **User-Friendly UI**: Clear visual states, progress bars, participant lists
4. ✅ **Secure**: JWT authentication on all endpoints
5. ✅ **Scalable**: Array-based system can handle many participants
6. ✅ **Real-time Updates**: UI updates immediately after join/leave
7. ✅ **Docker Compatible**: Works seamlessly in Docker environment
8. ✅ **Error Handled**: Proper validation and error messages

The join/leave feature is **production-ready** and enhances the event platform with social participation capabilities! 🚀
