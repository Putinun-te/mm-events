-- Add photo_id and photo_url columns to events table
-- This allows storing event pictures in S3

ALTER TABLE events 
ADD COLUMN photo_id VARCHAR(500) NULL COMMENT 'S3 key for event photo',
ADD COLUMN photo_url VARCHAR(1000) NULL COMMENT 'Public URL for event photo';

-- Add index for faster lookups
CREATE INDEX idx_events_photo_id ON events(photo_id);
