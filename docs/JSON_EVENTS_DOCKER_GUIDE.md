# JSON Events System - Docker Guide

## Overview
Events are now saved to and loaded from a JSON file (`data/events.json`) instead of only using the backend database. This provides a local data store that persists independently.

## Docker Setup ✅

### Volume Mapping
The frontend container has the following volume mount in `docker-compose.yml`:
```yaml
volumes:
  - ./main_frontend/concert1:/app
  - /app/node_modules
```

This means:
- ✅ The `data/events.json` file on your host is mapped to `/app/data/events.json` in the container
- ✅ All changes to the file are immediately reflected in both host and container
- ✅ Data persists even when containers restart

### Current Status
```bash
# Host file location:
/Users/putinan/development/DevOps/develop/main_frontend/concert1/data/events.json

# Container file location:
/app/data/events.json

# File is accessible: ✅
# File has write permissions: ✅
```

## How It Works

### 1. Create Event (Save to JSON)
```
User fills CreateEventPage form
→ Submit
→ POST /api/events/json
→ Server reads existing events.json
→ Adds new event with:
  - Unique ID (timestamp)
  - User info from JWT token
  - Timestamp (createdAt)
→ Writes back to events.json
→ Returns success
```

### 2. View Events (Load from JSON)
```
User visits ProductPage
→ GET /api/events/json
→ Server reads events.json
→ Returns array of events
→ Display in cards
```

### 3. Event Details
```
User clicks event card
→ Navigate to /ProductPageDetail/:id
→ GET /api/events/json/:id
→ Server reads events.json
→ Finds event by ID
→ Returns single event
→ Display details
```

### 4. My Events
```
User visits MyEventsPage
→ GET /api/events/json/me
→ Server reads events.json
→ Filters by current user ID (from JWT)
→ Returns user's events
→ Display in list
```

## Server Routes Created

All routes are in `main_frontend/concert1/server/api/events/json/`:

1. **`index.get.ts`** - Get all events from JSON
2. **`index.post.ts`** - Create new event in JSON
3. **`[id].get.ts`** - Get single event by ID from JSON
4. **`me.get.ts`** - Get current user's events from JSON

## Docker Commands

### Restart Frontend (After Code Changes)
```bash
cd /Users/putinan/development/DevOps/develop
docker compose restart frontend
```

### Check Frontend Logs
```bash
docker compose logs frontend --tail=50
```

### View JSON File in Container
```bash
docker compose exec frontend cat /app/data/events.json
```

### Check File Permissions in Container
```bash
docker compose exec frontend ls -la /app/data/
```

### Access Container Shell (for debugging)
```bash
docker compose exec frontend sh
# Then inside container:
cd /app/data
cat events.json
```

## File Structure

```json
[
  {
    "id": 1760350889162,
    "title": "Event Title",
    "description": "Event Description",
    "personLimit": 100,
    "startDate": "2025-10-13T17:21:00",
    "endDate": "2025-10-17T23:21:00",
    "ticketPrice": null,
    "address": null,
    "city": null,
    "country": null,
    "phone": null,
    "category": null,
    "location": null,
    "userId": 22,
    "userName": "User Name",
    "createdAt": "2025-10-13T10:21:29.162Z"
  }
]
```

## Data Flow Diagram

```
┌─────────────────┐
│ User Creates    │
│ Event           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Frontend        │
│ CreateEventPage │
└────────┬────────┘
         │ POST /api/events/json
         ▼
┌─────────────────────────┐
│ Nuxt Server Route       │
│ json/index.post.ts      │
│ - Extract JWT user info │
│ - Add timestamp ID      │
│ - Add createdAt         │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ File System (Container) │
│ /app/data/events.json   │
│ ↕️                       │
│ Host Volume Mount       │
│ ./concert1/data/events  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────┐
│ ProductPage     │
│ Loads events    │
│ from JSON       │
└─────────────────┘
```

## Testing

### 1. Create a New Event
1. Login to your account
2. Go to "Create Event" page
3. Fill out the form:
   - Title: "Test Event"
   - Description: "Testing JSON save"
   - Person Limit: 50
   - Start/End dates
4. Click "Create Event"
5. Check success message

### 2. Verify JSON File
```bash
# On host:
cat /Users/putinan/development/DevOps/develop/main_frontend/concert1/data/events.json

# Or in Docker:
docker compose exec frontend cat /app/data/events.json
```

### 3. View Events
1. Go to Product Page (Events List)
2. You should see your event displayed
3. Click on the event
4. Event details page should load

### 4. View My Events
1. Go to "My Events" page
2. You should see only events you created

## Troubleshooting

### Issue: Events not saving
**Solution:**
```bash
# Check file permissions
docker compose exec frontend ls -la /app/data/

# Restart frontend
docker compose restart frontend

# Check logs
docker compose logs frontend --tail=100
```

### Issue: File not found
**Solution:**
```bash
# Recreate the file
echo "[]" > /Users/putinan/development/DevOps/develop/main_frontend/concert1/data/events.json

# Restart container
docker compose restart frontend
```

### Issue: Changes not reflecting
**Solution:**
```bash
# Rebuild frontend container
docker compose up -d --build frontend

# Or restart
docker compose restart frontend
```

## Backup & Restore

### Backup Events
```bash
# Copy JSON file to backup
cp ./main_frontend/concert1/data/events.json ./main_frontend/concert1/data/events.backup.json

# Or from Docker
docker compose exec frontend cat /app/data/events.json > events.backup.json
```

### Restore Events
```bash
# Copy backup to active file
cp ./main_frontend/concert1/data/events.backup.json ./main_frontend/concert1/data/events.json
```

## Benefits

✅ **No Database Required** - Events work even if backend is down
✅ **Fast Performance** - Reading from JSON is instant
✅ **Easy Debugging** - Can view/edit file directly
✅ **Portable** - Can copy events.json between environments
✅ **Version Control** - Can track changes to events (if committed)
✅ **Docker Friendly** - Volume mount makes it seamless

## Production Notes

For production, consider:
1. **Sync to Database** - Periodically sync JSON to MySQL for backup
2. **File Size Limits** - Monitor JSON file size, archive old events
3. **Concurrent Access** - Add file locking for multiple users
4. **Validation** - Add schema validation before writing
5. **Error Handling** - Handle corrupt JSON gracefully

## Files Modified

- ✅ `server/api/events/json/index.get.ts` (NEW)
- ✅ `server/api/events/json/index.post.ts` (NEW)
- ✅ `server/api/events/json/[id].get.ts` (NEW)
- ✅ `server/api/events/json/me.get.ts` (NEW)
- ✅ `app/pages/CreateEventPage.vue` (Updated)
- ✅ `app/pages/ProductPage.vue` (Updated)
- ✅ `app/pages/ProductPageDetail/[id].vue` (Updated)
- ✅ `app/pages/MyEventsPage.vue` (Updated)
- ✅ `app/pages/AccountPage.vue` (Updated stats)
- ✅ `data/events.json` (NEW)

## Current Status: ✅ WORKING

Your first event is already saved:
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

🎉 JSON event system is fully operational with Docker!
