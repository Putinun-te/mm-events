import type { H3Event } from 'h3'
import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  if (getMethod(event).toUpperCase() === 'GET') {
    // GET: Read events from JSON file
    try {
      const data = await readFile(JSON_FILE_PATH, 'utf-8')
      const events = JSON.parse(data)
      return events
    } catch (err: any) {
      // If file doesn't exist, return empty array
      if (err.code === 'ENOENT') {
        return []
      }
      console.error('Error reading events.json:', err)
      setResponseStatus(event, 500)
      return { message: 'Failed to read events' }
    }
  } else if (getMethod(event).toUpperCase() === 'POST') {
    // POST: Add new event to JSON file
    try {
      const body = await readBody(event)
      
      // Read existing events
      let events = []
      try {
        const data = await readFile(JSON_FILE_PATH, 'utf-8')
        events = JSON.parse(data)
      } catch (err: any) {
        if (err.code !== 'ENOENT') {
          throw err
        }
      }
      
      // Get auth token to fetch user info
      const auth = getRequestHeader(event, 'authorization') || ''
      let userId = null
      let userName = null
      
      // Try to get user info from backend
      const config = useRuntimeConfig()
      const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'
      
      if (auth) {
        try {
          const userProfile: any = await $fetch(`${backend}/api/auth/me`, {
            headers: { Authorization: auth }
          })
          userId = userProfile.id
          userName = userProfile.name || userProfile.username
        } catch (e) {
          console.error('Failed to get user info:', e)
        }
      }
      
      // Create new event
      const newEvent = {
        id: Date.now(), // Simple ID generation
        ...body,
        userId,
        userName,
        createdAt: new Date().toISOString()
      }
      
      events.push(newEvent)
      
      // Ensure data directory exists
      const { mkdir } = await import('fs/promises')
      const { dirname } = await import('path')
      await mkdir(dirname(JSON_FILE_PATH), { recursive: true })
      
      // Write back to file
      await writeFile(JSON_FILE_PATH, JSON.stringify(events, null, 2), 'utf-8')
      
      return newEvent
    } catch (err: any) {
      console.error('Error saving event:', err)
      setResponseStatus(event, 500)
      return { message: err.message || 'Failed to save event' }
    }
  } else {
    setResponseStatus(event, 405)
    return { message: 'Method Not Allowed' }
  }
})
