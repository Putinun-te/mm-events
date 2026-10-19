-- Seat counts, an event's participant list and "cancel all bookings for this event"
-- all look bookings up by event; without an index each of them scans the table.
create index idx_bookings_event_status on bookings (event_id, status);
