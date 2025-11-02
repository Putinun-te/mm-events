import type { H3Event } from 'h3'
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { buildBackendUrl } from '../../../../utils/backend'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  const { id } = event.context.params || {}
  
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'Missing event id' })
  }

  // Get user info from auth token
  const auth = getRequestHeader(event, 'authorization') || ''
  if (!auth) {
    setResponseStatus(event, 401)
    return { message: 'Unauthorized - Please login to leave events' }
  }
  
  const config = useRuntimeConfig()
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'
  
  let userId = null
  
  try {
    const userProfile: any = await $fetch(buildBackendUrl(backend, '/api/auth/me'), {
      headers: { Authorization: auth }
    })
    userId = userProfile.id
  } catch (e) {
    console.error('Failed to get user info:', e)
    setResponseStatus(event, 401)
    return { message: 'Unauthorized - Could not verify user' }
  }

  try {
    // Read events
    const data = await readFile(JSON_FILE_PATH, 'utf-8')
    const events = JSON.parse(data)
    
    // Find the event
    const eventIndex = events.findIndex((e: any) => String(e.id) === String(id))
    
    if (eventIndex === -1) {
      setResponseStatus(event, 404)
      return { message: 'Event not found' }
    }
    
    const foundEvent = events[eventIndex]
    
    // Initialize participants array if it doesn't exist
    if (!foundEvent.participants) {
      foundEvent.participants = []
    }
    
    // Check if user is in participants
    const participantIndex = foundEvent.participants.findIndex((p: any) => p.userId === userId)
    
    if (participantIndex === -1) {
      return { 
        message: 'You are not a participant of this event',
        event: foundEvent,
        notJoined: true
      }
    }
    
    // Remove participant
    foundEvent.participants.splice(participantIndex, 1)
    
    // Update participants count
    foundEvent.participantsCount = foundEvent.participants.length
    
    // Save back to file
    await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
    
    // Note: The booking in the backend database will remain
    // To delete bookings, you would need to implement a DELETE /api/bookings/:id endpoint
    // For now, the booking stays but the user is removed from participants
    
    return {
      message: 'Successfully left event',
      event: foundEvent,
      left: true
    }
  } catch (err: any) {
    console.error('Error leaving event:', err)
    setResponseStatus(event, 500)
    return { message: 'Failed to leave event' }
  }
})
