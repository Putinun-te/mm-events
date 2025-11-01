# Event Deletion with Automatic Booking Cancellation

**Date:** October 16, 2025  
**Status:** ✅ Completed

## Problem

When an event organizer deleted an event, the participants (bookings) for that event were not automatically cancelled. This caused:
- Orphaned bookings in the database
- Users seeing bookings for non-existent events
- Inconsistent data between events and bookings

## Solution

Implemented automatic cancellation of all bookings when an event is deleted.

### Backend Changes

#### 1. **BookingRepository.java** - Added Query Method
```java
List<Booking> findByEventId(Long eventId);
```
- Enables finding all bookings associated with a specific event

#### 2. **BookingService.java** - Added Service Method
```java
@Transactional
public void cancelAllBookingsForEvent(Long eventId) {
    List<Booking> bookings = bookingRepository.findByEventId(eventId);
    for (Booking booking : bookings) {
        booking.setStatus("CANCELLED");
    }
    bookingRepository.saveAll(bookings);
}
```
- Marks all bookings for an event as "CANCELLED"
- Uses transaction to ensure atomicity

#### 3. **BookingController.java** - Added Endpoint
```java
@DeleteMapping("/event/{eventId}")
public ResponseEntity<Void> cancelAllBookingsForEvent(
        @PathVariable Long eventId,
        Authentication authentication) {
    bookingService.cancelAllBookingsForEvent(eventId);
    return ResponseEntity.noContent().build();
}
```
- New endpoint: `DELETE /api/bookings/event/{eventId}`
- Requires authentication

### Frontend Changes

#### 4. **[id].delete.ts** - Updated Event Deletion Handler
```typescript
// Cancel all bookings for this event
try {
  await $fetch(`${backend}/api/bookings/event/${eventId}`, {
    method: 'DELETE',
    headers: { Authorization: auth }
  })
} catch (bookingError: any) {
  console.error('Failed to cancel bookings for event:', bookingError)
  // Continue even if booking cancellation fails
}
```
- Calls the new backend endpoint after deleting the event
- Gracefully handles errors (event is still deleted even if booking cancellation fails)

## Flow

1. **User deletes event** (from EditEventPage.vue)
2. **Frontend sends DELETE request** to `/api/events/json/{id}`
3. **Server-side handler**:
   - Verifies user ownership
   - Removes event from JSON file
   - **Calls backend to cancel all bookings** for that event
4. **Backend BookingController**:
   - Receives DELETE request at `/api/bookings/event/{eventId}`
   - Finds all bookings with matching eventId
   - Sets status to "CANCELLED" for all found bookings
5. **Frontend redirects** to MyEventsPage

## Testing

### Manual Testing Steps:

1. **Create an event** as an organizer
2. **Book tickets** for that event (with multiple users if possible)
3. **Check "My Bookings"** - should see active bookings
4. **Delete the event** as the organizer
5. **Check "My Bookings" again** - bookings should show as "CANCELLED"
6. **Check participants view** - should show no participants (or cancelled status)

### Expected Behavior:

✅ Event is deleted successfully  
✅ All bookings for that event are marked as "CANCELLED"  
✅ Users can see their cancelled bookings in history  
✅ Cancelled bookings don't appear in active participants list  
✅ Database remains consistent  

## Additional Security Considerations

- The endpoint requires authentication
- Only event organizers can delete events (verified in delete handler)
- Booking cancellation happens automatically and doesn't require individual user authorization
- Transaction ensures all-or-nothing operation

## Files Modified

### Backend
- `main_backend/src/main/java/com/concert/repository/BookingRepository.java`
- `main_backend/src/main/java/com/concert/service/BookingService.java`
- `main_backend/src/main/java/com/concert/controller/BookingController.java`

### Frontend
- `main_frontend/concert1/server/api/events/json/[id].delete.ts`

## Notes

- Bookings are **cancelled** (status = "CANCELLED"), not deleted
- This preserves historical data for reporting and auditing
- Users can still see their cancelled bookings in "My Bookings" page
- The event JSON file is updated first, then bookings are cancelled
- If booking cancellation fails, the event is still deleted (to prevent orphaned events)

## Future Enhancements

1. **Email notifications** to users when their bookings are cancelled due to event deletion
2. **Refund processing** if payment integration is added
3. **Audit log** for event deletions and mass booking cancellations
4. **Soft delete** for events instead of hard delete (keep in database with deleted flag)
