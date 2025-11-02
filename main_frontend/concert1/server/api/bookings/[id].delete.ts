import type { H3Event } from 'h3'
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { buildBackendUrl } from '../../utils/backend'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event) => {
  const bookingId = getRouterParam(event, 'id')
  
  if (!bookingId) {
    throw createError({ statusCode: 400, statusMessage: 'Booking ID is required' })
  }

  const config = useRuntimeConfig()
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'

  const token = getHeader(event, 'authorization')
  if (!token) {
    throw createError({ statusCode: 401, statusMessage: 'Authorization header missing' })
  }

  try {
    // First, get the booking details to know which event and user
    let bookingDetails: any = null
    try {
      const bookingResponse = await fetch(buildBackendUrl(backend, `/api/bookings/${bookingId}`), {
        method: 'GET',
        headers: { Authorization: token }
      })
      if (bookingResponse.ok) {
        bookingDetails = await bookingResponse.json()
      }
    } catch (e) {
      console.error('Could not fetch booking details:', e)
    }

    // Cancel the booking in the backend database
    const response = await fetch(buildBackendUrl(backend, `/api/bookings/${bookingId}`), {
      method: 'DELETE',
      headers: { Authorization: token }
    })
    
    if (!response.ok) {
      throw createError({ 
        statusCode: response.status, 
        statusMessage: `Failed to cancel booking: ${response.statusText}` 
      })
    }

    // Get user info to remove from participants
    let userId = null
    try {
      const userProfile: any = await $fetch(buildBackendUrl(backend, '/api/auth/me'), {
        headers: { Authorization: token }
      })
      userId = userProfile.id
    } catch (e) {
      console.error('Could not get user info:', e)
    }

    // Update the JSON file to reduce participants count
    if (bookingDetails && bookingDetails.eventId && userId) {
      try {
        const data = await readFile(JSON_FILE_PATH, 'utf-8')
        const events = JSON.parse(data)
        
        // Find the event by ID
        const eventIndex = events.findIndex((e: any) => 
          String(e.id) === String(bookingDetails.eventId)
        )
        
        if (eventIndex !== -1) {
          const foundEvent = events[eventIndex]
          
          // Initialize participants array if needed
          if (!foundEvent.participants) {
            foundEvent.participants = []
          }
          
          // Find the participant by userId
          const participant = foundEvent.participants.find((p: any) => p.userId === userId)
          
          if (participant) {
            const cancelledQuantity = bookingDetails.quantity || 1
            const currentTicketCount = participant.ticketCount || 0
            
            // Reduce ticket count by the cancelled booking quantity
            participant.ticketCount = Math.max(0, currentTicketCount - cancelledQuantity)
            
            // If ticket count reaches 0, remove the participant entirely
            if (participant.ticketCount === 0) {
              const participantIndex = foundEvent.participants.findIndex((p: any) => p.userId === userId)
              foundEvent.participants.splice(participantIndex, 1)
              console.log(`✅ Removed participant ${userId} from event ${bookingDetails.eventId} (all tickets cancelled)`)
            } else {
              console.log(`✅ Reduced ${cancelledQuantity} ticket(s) for participant ${userId} in event ${bookingDetails.eventId} (${participant.ticketCount} remaining)`)
            }
            
            // Update participants count (sum of all ticket counts)
            foundEvent.participantsCount = foundEvent.participants.reduce(
              (sum: number, p: any) => sum + (p.ticketCount || 0),
              0
            )
            
            // Save back to file
            await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
          } else {
            console.log(`⚠️ Participant ${userId} not found in event ${bookingDetails.eventId}`)
          }
        }
      } catch (fileErr) {
        // Log error but don't fail the cancellation
        console.error('Failed to update participants in JSON:', fileErr)
      }
    }
    
    // Return 204 No Content on success
    setResponseStatus(event, 204)
    return null
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500
    const message = err?.data?.message || err?.response?._data?.message || err?.message || 'Failed to cancel booking'
    throw createError({ statusCode: status, statusMessage: message })
  }
})
