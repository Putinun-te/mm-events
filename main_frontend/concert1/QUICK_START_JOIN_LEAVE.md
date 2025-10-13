# 🎉 Event Join/Leave Feature - Quick Start Guide

## What's New?

Your event platform now has **social participation features**! Users can join events to show interest and track attendance without booking tickets.

## 🚀 Quick Demo Flow

### 1. Browse Events (ProductPage)
```
┌─────────────────────────────┐
│  🎵 Music Festival          │  ← Event Card
│  Oct 15, 2025               │
│  📍 City Center             │
│  👥 25  ← Participants Badge│
└─────────────────────────────┘
```

### 2. View Event Details (ProductPageDetail/:id)
```
┌──────────────────────────────────────────┐
│  🎵 Music Festival                       │
│  ────────────────────────────────────    │
│  📅 Oct 15, 2025                         │
│  📍 City Center                          │
│  👤 Organizer: John Doe                  │
│                                          │
│  ╔════════════════════════════════════╗  │
│  ║ 👥 Participants: 25 / 100          ║  │
│  ║ ████████░░░░░░░░░░░░░░░░ 25%       ║  │
│  ║ 75 spots remaining                 ║  │
│  ╚════════════════════════════════════╝  │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │      🎉 Join Event               │   │ ← Join Button
│  └──────────────────────────────────┘   │
│                                          │
│  📋 Participants (25):                   │
│  ┌────────────────────────────────┐     │
│  │ 👤 Jane Smith  ✓ Joined       │     │
│  │    Jan 13, 2025               │     │
│  ├────────────────────────────────┤     │
│  │ 👤 Mike Johnson ✓ Joined      │     │
│  │    Jan 13, 2025               │     │
│  └────────────────────────────────┘     │
└──────────────────────────────────────────┘
```

### 3. After Joining
```
┌──────────────────────────────────────────┐
│  ┌──────────────────┐ ┌───────────────┐  │
│  │ ✓ You're Joined  │ │ Leave Event   │  │ ← State changes
│  └──────────────────┘ └───────────────┘  │
│                                          │
│  👥 Participants: 26 / 100  ← Count ++   │
│  ████████░░░░░░░░░░░░░░░░ 26%           │
│                                          │
│  📋 Participants (26):                   │
│  ┌────────────────────────────────┐     │
│  │ 👤 You (Current User) ✓        │     │ ← You appear here!
│  │    Jan 13, 2025               │     │
│  └────────────────────────────────┘     │
└──────────────────────────────────────────┘
```

### 4. My Events Page (with Tabs)
```
┌────────────────────────────────────────────┐
│  My Events                  [Create Event] │
│  ─────────────────────────────────────────  │
│  📝 Created (3)    🎉 Joined (5)  ← Tabs   │
│  ──────────────    ─────────────────       │
│                                            │
│  🎉 Joined Events:                         │
│  ┌──────────────────────────────────────┐ │
│  │ 🎵 Music Festival                    │ │
│  │ Oct 15 | 10:00 AM - 6:00 PM         │ │
│  │ 👤 By: John Doe                      │ │
│  │                        ✓ Joined  →  │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ 🎭 Theater Night                     │ │
│  │ Oct 20 | 7:00 PM - 10:00 PM         │ │
│  │ 👤 By: Sarah Lee                     │ │
│  │                        ✓ Joined  →  │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

## 🎯 Key Features

### ✨ For Users
- ✅ **Join events** to show interest
- ✅ **Auto-creates booking** - appears in "My Bookings" (quantity: 1)
- ✅ **Track joined events** in My Events tab
- ✅ **See participants** and capacity
- ✅ **Leave anytime** with one click
- ✅ **Visual progress bar** showing capacity

### 🔧 For Developers
- ✅ **3 new API endpoints** (join, leave, joined)
- ✅ **JWT authentication** on all endpoints
- ✅ **JSON file storage** (no database needed)
- ✅ **Backend booking integration** - creates MySQL booking automatically
- ✅ **Real-time UI updates** after actions
- ✅ **Comprehensive error handling**

## 📡 API Endpoints

```typescript
// Join an event
POST /api/events/json/:id/join
Headers: { Authorization: 'Bearer <token>' }
Response: { joined: true, event: {...} }

// Leave an event
POST /api/events/json/:id/leave
Headers: { Authorization: 'Bearer <token>' }
Response: { left: true, event: {...} }

// Get joined events
GET /api/events/json/joined
Headers: { Authorization: 'Bearer <token>' }
Response: [ {...events...} ]
```

## 🎨 UI Components Updated

### ProductPageDetail
- ✅ Join/Leave buttons
- ✅ Participants progress bar
- ✅ Participants list with avatars
- ✅ Capacity indicator

### ProductCard
- ✅ Participants count badge (👥 25)

### MyEventsPage
- ✅ Tab system (Created / Joined)
- ✅ Joined events with organizer info
- ✅ Different styling for joined events

## 🧪 How to Test

### 1. Start Docker Containers
```bash
docker compose up -d
```

### 2. Open App
```
http://localhost:3000
```

### 3. Test Flow
1. **Login** to your account
2. **Browse events** (see participant badges)
3. **Click an event** to view details
4. **Click "Join Event"** button
5. **See yourself** in participants list
6. **Go to "My Events"** page
7. **Click "Joined" tab** to see all joined events
8. **Click "Leave Event"** to leave

### 4. Test Edge Cases
- ✅ Join when **not logged in** → Login prompt
- ✅ Join **full event** → "Event Full" message
- ✅ Join **already joined** → "Already joined" message
- ✅ Multiple users join → Count increases
- ✅ Leave event → Removed from list

## 📊 Data Structure

### Event with Participants
```json
{
  "id": 123,
  "title": "Music Festival",
  "personLimit": 100,
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

## 🎪 Visual States

### Join Button States
```
Not Logged In:    [ Please login to join this event ]
                  
Available:        [ 🎉 Join Event ]
                  
Joining:          [ ⏳ Joining... ]
                  
Joined:           [ ✓ You're Joined ] [ Leave Event ]
                  
Full:             [ 🚫 Event Full ]
```

### Capacity Display
```
Empty:     ░░░░░░░░░░░░░░░░░░░░ 0/100
Quarter:   █████░░░░░░░░░░░░░░░ 25/100
Half:      ██████████░░░░░░░░░░ 50/100
Full:      ████████████████████ 100/100
```

## 🔐 Security

All endpoints require **JWT authentication**:
- Token from `localStorage` or `sessionStorage`
- Bearer token format: `Authorization: Bearer <token>`
- User validation via backend `/api/auth/me`

## 🚀 Production Ready

✅ **Complete Implementation**
- All endpoints working
- UI fully implemented
- Error handling done
- Docker compatible

✅ **User Experience**
- Intuitive UI/UX
- Clear visual feedback
- Responsive design
- Mobile friendly

✅ **Data Persistence**
- JSON file storage
- Atomic file operations
- Docker volume mount
- Data survives restarts

## 📝 Files Changed

### New Files
```
server/api/events/json/[id]/join.post.ts    ← Join endpoint
server/api/events/json/[id]/leave.post.ts   ← Leave endpoint
server/api/events/json/joined.get.ts        ← Joined events endpoint
JOIN_LEAVE_FEATURE.md                        ← Full documentation
QUICK_START_JOIN_LEAVE.md                    ← This file
```

### Updated Files
```
app/pages/ProductPageDetail/[id].vue        ← Join/Leave UI
app/pages/MyEventsPage.vue                  ← Tabs system
app/components/ProductCard.vue              ← Participants badge
```

## 🎊 Congratulations!

Your event platform now has a **fully functional social participation system**! 🚀

Users can:
- 🎉 Join events they're interested in
- 👥 See other participants
- 📊 Track event capacity
- 📝 Manage joined events in one place
- 🚪 Leave events anytime

**The feature is live and ready to use!** Just restart Docker if needed:

```bash
docker compose restart frontend
```

Then open `http://localhost:3000` and start joining events! 🎪
