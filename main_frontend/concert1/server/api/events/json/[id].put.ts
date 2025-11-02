import type { H3Event } from 'h3'
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { buildBackendUrl } from '../../../utils/backend'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  try {
    const eventId = getRouterParam(event, 'id')
    const body = await readBody(event)
    
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
      const userProfile: any = await $fetch(buildBackendUrl(backend, '/api/auth/me'), {
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
      return { message: 'You do not have permission to edit this event' }
    }
    
    // Update event (preserve id, userId, userName, createdAt)
    const updatedEvent = {
      ...existingEvent,
      ...body,
      id: existingEvent.id,
      userId: existingEvent.userId,
      userName: existingEvent.userName,
      createdAt: existingEvent.createdAt,
      updatedAt: new Date().toISOString()
    }
    
    events[eventIndex] = updatedEvent
    
    // Write back to file
    await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
    
    return updatedEvent
  } catch (err: any) {
    console.error('Error updating event:', err)
    setResponseStatus(event, 500)
    return { message: err.message || 'Failed to update event' }
  }
})
