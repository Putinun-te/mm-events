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
    return { message: 'Unauthorized - Please login to join events' }
  }
  
  const config = useRuntimeConfig()
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'
  
  let userId = null
  let userName = null
  
  try {
    const userProfile: any = await $fetch(buildBackendUrl(backend, '/api/auth/me'), {
      headers: { Authorization: auth }
    })
    userId = userProfile.id
    userName = userProfile.name || userProfile.username
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
    
    // Check if user already joined
    const alreadyJoined = foundEvent.participants.some((p: any) => p.userId === userId)
    
    if (alreadyJoined) {
      return { 
        message: 'You have already joined this event',
        event: foundEvent,
        alreadyJoined: true
      }
    }
    
    // Check person limit
    if (foundEvent.personLimit && foundEvent.participants.length >= foundEvent.personLimit) {
      setResponseStatus(event, 400)
      return { message: 'Event is full - no more spots available' }
    }
    
    // Add participant
    foundEvent.participants.push({
      userId,
      userName,
      joinedAt: new Date().toISOString()
    })
    
    // Update participants count
    foundEvent.participantsCount = foundEvent.participants.length
    
    // Save back to file
    await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
    
    // Also create a booking in the backend so it shows in "My Bookings"
    try {
  await $fetch(buildBackendUrl(backend, '/api/bookings'), {
        method: 'POST',
        body: {
          eventId: String(foundEvent.id),
          quantity: 1,
          eventTitle: foundEvent.title || foundEvent.name,
          eventLocation: foundEvent.location || (foundEvent.city ? `${foundEvent.city}${foundEvent.country ? ', ' + foundEvent.country : ''}` : null),
          eventStartDate: foundEvent.startDate || foundEvent.datestart,
          ticketPrice: foundEvent.ticketPrice || 0
        },
        headers: { Authorization: auth }
      })
      console.log(`✓ Created booking for user ${userId} joining event ${foundEvent.id}`)
    } catch (bookingError: any) {
      console.warn('Warning: Failed to create booking, but user is still joined to event:', bookingError)
      // Don't fail the join if booking fails - user is still joined to the event
      // This ensures join works even if backend is down
    }
    
    return {
      message: 'Successfully joined event!',
      event: foundEvent,
      joined: true
    }
  } catch (err: any) {
    console.error('Error joining event:', err)
    setResponseStatus(event, 500)
    return { message: 'Failed to join event' }
  }
})
