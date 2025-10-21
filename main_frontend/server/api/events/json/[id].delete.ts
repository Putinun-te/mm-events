import type { H3Event } from 'h3'
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  try {
    const eventId = getRouterParam(event, 'id')
    
    // Get auth token to verify ownership
    const auth = getRequestHeader(event, 'authorization') || ''
    if (!auth) {
      setResponseStatus(event, 401)
      return { message: 'Authentication required' }
    }
    
    // Get user info from backend
    const config = useRuntimeConfig()
    const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'
    
    let userId = null
    try {
      const userProfile: any = await $fetch(`${backend}/api/auth/me`, {
        headers: { Authorization: auth }
      })
      userId = userProfile.id
    } catch (e: any) {
      console.error('Failed to verify user:', e?.message || e)
      setResponseStatus(event, 401)
      return { message: 'Authentication failed' }
    }
    
    // Read existing events
    let events = []
    try {
      const data = await readFile(JSON_FILE_PATH, 'utf-8')
      events = JSON.parse(data)
    } catch (err: any) {
      if (err.code === 'ENOENT') {
        setResponseStatus(event, 404)
        return { message: 'Event not found' }
      }
      throw err
    }
    
    // Find event by ID and verify ownership
    const eventIndex = events.findIndex((e: any) => String(e.id) === String(eventId))
    if (eventIndex === -1) {
      setResponseStatus(event, 404)
      return { message: 'Event not found' }
    }
    
    const existingEvent = events[eventIndex]
    if (existingEvent.userId && String(existingEvent.userId) !== String(userId)) {
      setResponseStatus(event, 403)
      return { message: 'You do not have permission to delete this event' }
    }
    
    // Remove event from array
    events.splice(eventIndex, 1)
    
    // Write back to file
    await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
    
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
    
    setResponseStatus(event, 204)
    return null
  } catch (err: any) {
    console.error('Error deleting event:', err)
    setResponseStatus(event, 500)
    return { message: err.message || 'Failed to delete event' }
  }
})
