# JSON Event Storage Implementation

## Overview
Implemented a JSON-based event storage system where created events are saved to a local JSON file and read from it on the ProductPage and other pages.

## How It Works

### 1. Event Creation Flow
```
User fills Create Event form
→ Submits form
→ POST /api/events/json
→ Reads existing events.json
→ Adds new event with auto-generated ID (timestamp)
→ Saves user info (userId, userName) from JWT token
→ Writes updated array back to events.json
→ Returns created event
→ Redirects to ProductPage
```

### 2. Event Display Flow
```
ProductPage loads
→ GET /api/events/json
→ Reads events.json
→ Returns all events as array
→ Displays in card grid with search/filter
```

### 3. Event Detail Flow
```
User clicks event card
→ Navigate to /ProductPageDetail/:id
→ GET /api/events/json/:id
→ Reads events.json
→ Finds event by ID
→ Returns single event
→ Displays full details
```

### 4. My Events Flow
```
MyEventsPage loads
→ GET /api/events/json/me
→ Authenticates user via JWT
→ Gets userId from backend /api/auth/me
→ Filters events.json by userId
→ Returns user's events
→ Displays in list
```

## Files Created

### Server Routes (Nuxt Server API)

1. **`server/api/events/json.ts`**
   - Handles: GET (all events), POST (create event)
   - GET: Returns all events from events.json
   - POST: Adds new event with userId, userName, createdAt, auto-generated ID
   - Creates data directory if needed

2. **`server/api/events/json/[id].get.ts`**
   - Handles: GET single event by ID
   - Returns event matching the ID parameter

3. **`server/api/events/json/me.get.ts`**
   - Handles: GET user's events
   - Authenticates user via JWT
   - Filters events by userId
   - Returns only events created by current user

### Data Storage

4. **`data/events.json`**
   - Location: `main_frontend/concert1/data/events.json`
   - Initial state: Empty array `[]`
   - Structure:
     ```json
     [
       {
         "id": 1697123456789,
         "title": "Music Festival 2025",
         "description": "Amazing festival",
         "personLimit": 1000,
         "startDate": "2025-11-15T18:00:00",
         "endDate": "2025-11-15T23:00:00",
         "ticketPrice": 50,
         "address": "Central Park",
         "city": "New York",
         "country": "USA",
         "phone": "555-1234",
         "category": "Music",
         "location": "Central Park, NY",
         "userId": 1,
         "userName": "John Doe",
         "createdAt": "2025-10-13T10:30:00.000Z"
       }
     ]
     ```

## Files Modified

### Frontend Pages

1. **`app/pages/CreateEventPage.vue`**
   - Changed endpoint from `/api/events` to `/api/events/json`
   - Updated success message to mention JSON storage
   - Redirects to `/ProductPage` after creation

2. **`app/pages/ProductPage.vue`**
   - Changed from `useFetch('/api/events')` to `$fetch('/api/events/json')`
   - Now loads all events from JSON file
   - Filters work with JSON data

3. **`app/pages/ProductPageDetail/[id].vue`**
   - Changed from `/api/events/${id}` to `/api/events/json/${id}`
   - Fetches single event from JSON

4. **`app/pages/MyEventsPage.vue`**
   - Changed from `/api/events/me` to `/api/events/json/me`
   - Shows only user's created events

5. **`app/pages/AccountPage.vue`**
   - Updated stats loading to use `/api/events/json/me`
   - Events Created count now from JSON

## Event Data Structure

Each event in JSON contains:

### Required Fields:
- `id` (number) - Auto-generated timestamp
- `title` (string) - Event name
- `description` (string) - Event description
- `startDate` (ISO string) - Event start datetime
- `endDate` (ISO string) - Event end datetime

### Optional Fields:
- `personLimit` (number) - Max attendees
- `ticketPrice` (number) - Price per ticket
- `address` (string) - Street address
- `city` (string) - City
- `country` (string) - Country
- `phone` (string) - Contact phone
- `category` (string) - Event category (Music, Sports, Tech, Art, Food, Business, Other)
- `location` (string) - Full location description

### Auto-Added Fields:
- `userId` (number) - Creator's user ID from database
- `userName` (string) - Creator's name from database
- `createdAt` (ISO string) - Creation timestamp

## Authentication

All write operations (POST) and user-specific reads (GET /me) require:
- JWT token in Authorization header
- Format: `Bearer <token>`
- Token validated against backend `/api/auth/me`

## Features

### Search & Filter (ProductPage)
- ✅ Search by title, description, location
- ✅ Filter by category (Music, Sports, Tech, Art, Food, Business, Other)
- ✅ Filter by date
- ✅ Clear all filters button
- ✅ Results count display

### Event Display
- ✅ Card grid layout on ProductPage
- ✅ Full detail view on ProductPageDetail
- ✅ My Events list on MyEventsPage
- ✅ Event count in Account stats

### Data Persistence
- ✅ Events saved to JSON file
- ✅ Survives server restart (file-based)
- ✅ User ownership tracked
- ✅ Creation timestamp recorded

## File Location

```
main_frontend/concert1/
├── data/
│   └── events.json              # Event storage file
├── server/
│   └── api/
│       └── events/
│           ├── json.ts          # Create & list all events
│           └── json/
│               ├── [id].get.ts  # Get single event
│               └── me.get.ts    # Get user's events
└── app/
    └── pages/
        ├── CreateEventPage.vue  # Create event → JSON
        ├── ProductPage.vue      # List all events from JSON
        ├── ProductPageDetail/
        │   └── [id].vue         # Show event from JSON
        ├── MyEventsPage.vue     # List user's events from JSON
        └── AccountPage.vue      # Stats from JSON
```

## Testing

### Test Event Creation:
1. Go to CreateEventPage
2. Fill out event form
3. Click "Create Event"
4. Check `data/events.json` - new event added ✅
5. Redirected to ProductPage - event appears ✅

### Test Event Display:
1. Go to ProductPage
2. See all events from JSON ✅
3. Use search/filters ✅
4. Click event card → Detail page ✅

### Test My Events:
1. Go to MyEventsPage
2. See only your created events ✅
3. Events from other users not shown ✅

### Test Account Stats:
1. Go to AccountPage
2. "Events Created" shows count from JSON ✅
3. Matches events in MyEventsPage ✅

## Advantages

✅ **Simple Storage** - No database needed for events
✅ **File-Based** - Easy to backup/restore
✅ **Version Control** - JSON file can be committed
✅ **Fast Reads** - No database queries
✅ **Portable** - Works in any environment
✅ **User Tracking** - Events linked to creators
✅ **Searchable** - All data in one file

## Notes

- Events are stored in `data/events.json` as an array
- Each event gets a unique ID based on timestamp
- User info (userId, userName) fetched from backend on creation
- File is created automatically if it doesn't exist
- Events persist across server restarts
- Compatible with existing ProductCard component
- Works with search, filters, and detail views

## Next Steps (Optional Enhancements)

- Add event editing (update events.json)
- Add event deletion (remove from events.json)
- Add event image upload
- Add pagination for large event lists
- Add event categories management
- Add event status (draft, published, cancelled)
- Add event analytics/views counter
- Export events to CSV/Excel
- Import events from CSV
