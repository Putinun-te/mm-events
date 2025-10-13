import type { H3Event } from 'h3'
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  try {
    const eventId = getRouterParam(event, 'id')
    const body = await readBody(event)
    const { userId, userName, ticketCount } = body
    
    // Read existing events
    let events = []
    try {
      const data = await readFile(JSON_FILE_PATH, 'utf-8')
      events = JSON.parse(data)
    } catch (err: any) {
      if (err.code === 'ENOENT') {
        setResponseStatus(event, 404)
        return { message: 'Events file not found' }
      }
      throw err
    }
    
    // Find event by ID
    const eventIndex = events.findIndex((e: any) => String(e.id) === String(eventId))
    if (eventIndex === -1) {
      setResponseStatus(event, 404)
      return { message: 'Event not found' }
    }
    
    const targetEvent = events[eventIndex]
    
    // Initialize participants array if it doesn't exist
    if (!targetEvent.participants) {
      targetEvent.participants = []
    }
    
    // Check if user already exists in participants
    const existingParticipant = targetEvent.participants.find((p: any) => p.userId === userId)
    
    if (existingParticipant) {
      // Update ticket count for existing participant
      existingParticipant.ticketCount = (existingParticipant.ticketCount || 0) + ticketCount
      existingParticipant.lastBookedAt = new Date().toISOString()
    } else {
      // Add new participant
      targetEvent.participants.push({
        userId,
        userName: userName || 'Anonymous',
        ticketCount,
        joinedAt: new Date().toISOString()
      })
    }
    
    // Update participantsCount
    targetEvent.participantsCount = targetEvent.participants.reduce(
      (sum: number, p: any) => sum + (p.ticketCount || 0), 
      0
    )
    
    // Write back to file
    events[eventIndex] = targetEvent
    await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
    
    return {
      success: true,
      participantsCount: targetEvent.participantsCount,
      participants: targetEvent.participants
    }
  } catch (err: any) {
    console.error('Error adding participant:', err)
    setResponseStatus(event, 500)
    return { message: err.message || 'Failed to add participant' }
  }
})
