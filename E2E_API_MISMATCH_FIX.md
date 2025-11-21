# E2E API Mismatch Fix

**Date:** November 22, 2025  
**Commit:** `5ae1239`  
**Branch:** `release/v1.0.0`

## Problem

Frontend E2E tests were **failing** because they were testing against **incorrect API endpoints and field names** that didn't match the actual backend implementation.

### Root Cause Analysis

1. **Incorrect Endpoints:**
   - Tests used: `/api/events/json` (doesn't exist)
   - Actual endpoint: `/api/events` (correct)

2. **Field Name Mismatches:**
   - Tests used: `price`, `capacity`, `imageUrl`
   - Backend expects: `ticketPrice`, `personLimit` (no `imageUrl` in CreateEventRequest)

3. **Response Structure Mismatch:**
   - Tests expected: Array of events directly
   - Backend returns: Paginated response `Page<EventResponse>` with `.content` array

4. **Status Code Mismatch:**
   - Tests expected: 201 Created
   - Backend returns: 200 OK for event creation

## Solution

Updated `main_frontend/concert1/test/e2e/api-integration.e2e.test.ts` to align with actual backend API contract.

### Changes Made

#### 1. Endpoint Corrections
```diff
- await axios.get(`${API_BASE}/api/events/json`)
+ await axios.get(`${API_BASE}/api/events`)

- await axios.post(`${API_BASE}/api/events/json`, newEvent, ...)
+ await axios.post(`${API_BASE}/api/events`, newEvent, ...)

- await axios.get(`${API_BASE}/api/events/json/${eventId}`)
+ await axios.get(`${API_BASE}/api/events/${eventId}`)
```

#### 2. Field Name Updates
```diff
const newEvent = {
  title: `E2E Test Event ${Date.now()}`,
  description: 'Created by E2E test',
  startDate: new Date(Date.now() + 86400000).toISOString(),
  endDate: new Date(Date.now() + 172800000).toISOString(),
-  price: 99.99,
-  capacity: 100,
+  ticketPrice: 99.99,
+  personLimit: 100,
  location: 'Test Venue',
-  imageUrl: 'https://example.com/image.jpg'
}
```

#### 3. Response Structure Handling
```diff
const response = await axios.get(`${API_BASE}/api/events`)
expect(response.status).toBe(200)
- expect(Array.isArray(response.data)).toBe(true)
+ expect(response.data).toHaveProperty('content')
+ expect(Array.isArray(response.data.content)).toBe(true)
+ expect(response.data).toHaveProperty('totalElements')
+ expect(response.data).toHaveProperty('totalPages')

- const foundEvent = response.data.find((e: any) => e.id === eventId)
+ const foundEvent = response.data.content.find((e: any) => e.id === eventId)
```

#### 4. Status Code Updates
```diff
const createResponse = await axios.post(`${API_BASE}/api/events`, event, ...)
- expect(createResponse.status).toBe(201)
+ expect(createResponse.status).toBe(200)
```

#### 5. Added Pagination Tests
```typescript
it('should fetch events with pagination parameters', async () => {
  const response = await axios.get(`${API_BASE}/api/events?page=0&size=5`)
  expect(response.status).toBe(200)
  expect(response.data).toHaveProperty('content')
  expect(Array.isArray(response.data.content)).toBe(true)
  expect(response.data.content.length).toBeLessThanOrEqual(5)
})
```

## Backend API Reference

### Event Endpoints (from EventController.java)

| Method | Endpoint | Request Body | Response | Auth Required |
|--------|----------|--------------|----------|---------------|
| POST | `/api/events` | `CreateEventRequest` | `EventResponse` (200) | Yes |
| GET | `/api/events` | Query params: `page`, `size` | `Page<EventResponse>` (200) | No |
| GET | `/api/events/{id}` | - | `EventResponse` (200) | No |
| PUT | `/api/events/{id}` | `CreateEventRequest` | `EventResponse` (200) | Yes |
| DELETE | `/api/events/{id}` | - | 204 No Content | Yes |
| GET | `/api/events/me` | - | `List<EventResponse>` (200) | Yes |

### CreateEventRequest DTO Fields

**Required:**
- `title`: String (@NotBlank)
- `startDate`: LocalDateTime (@NotNull)
- `endDate`: LocalDateTime (@NotNull)

**Optional:**
- `description`: String
- `category`: String
- `location`: String
- `address`: String
- `city`: String
- `country`: String
- `personLimit`: Integer
- `phone`: String
- `ticketPrice`: Double
- `photoUrl`: String

### Page<EventResponse> Structure

```json
{
  "content": [...],
  "totalElements": 100,
  "totalPages": 10,
  "size": 12,
  "number": 0,
  "numberOfElements": 12,
  "first": true,
  "last": false,
  "empty": false
}
```

## Test Coverage

Updated E2E test suites now correctly test:

1. ✅ Backend actuator health endpoint
2. ✅ Auth test endpoint
3. ✅ Frontend server responding
4. ✅ User registration flow
5. ✅ User login flow
6. ✅ Invalid credential rejection
7. ✅ Events list retrieval (paginated)
8. ✅ Events list with pagination parameters
9. ✅ Event creation with authentication
10. ✅ Event creation rejection without auth
11. ✅ Full user journey: register → login → create event → fetch events → fetch single event

## Expected Outcome

With these fixes, the Frontend E2E tests should now:
- ✅ Pass successfully in the CI/CD pipeline
- ✅ Test the actual API contract
- ✅ Validate paginated responses correctly
- ✅ Use correct field names matching backend DTOs
- ✅ Expect correct HTTP status codes

## Next Steps

1. ✅ Monitor the pipeline run for `release/v1.0.0`
2. ⏳ Verify E2E tests pass successfully
3. ⏳ Review pipeline summary for overall success
4. 📝 Update frontend API client code to use correct field names if needed

## Related Files

- **Test File:** `main_frontend/concert1/test/e2e/api-integration.e2e.test.ts`
- **Backend Controller:** `main_backend/src/main/java/com/concert/controller/EventController.java`
- **Backend DTO:** `main_backend/src/main/java/com/concert/dto/CreateEventRequest.java`
- **Workflow:** `.github/workflows/full-pipeline.yml`

## Lessons Learned

1. **Always verify API contracts** before writing E2E tests
2. **Check backend DTOs** for correct field names and validation rules
3. **Understand response structures** (array vs paginated vs single object)
4. **Match HTTP status codes** to actual backend responses
5. **Keep tests synchronized** with API changes

---

**Pipeline Status:** 🔄 Running  
**Expected Result:** ✅ All E2E tests pass  
**GitHub Actions:** https://github.com/MorningMores/develop/actions
