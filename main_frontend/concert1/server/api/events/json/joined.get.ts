import type { H3Event } from 'h3'
import { readFile } from 'fs/promises'
import { join } from 'path'
import { buildBackendUrl } from '../../../utils/backend'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  try {
    // Get user info from auth token
    const auth = getRequestHeader(event, 'authorization') || ''
    if (!auth) {
      setResponseStatus(event, 401)
      return { message: 'Unauthorized' }
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
      return { message: 'Unauthorized' }
    }
    
    // Read events from JSON
    try {
      const data = await readFile(JSON_FILE_PATH, 'utf-8')
      const events = JSON.parse(data)
      
      // Filter events where user is a participant
      const joinedEvents = events.filter((e: any) => {
        if (!e.participants) return false
        return e.participants.some((p: any) => p.userId === userId)
      })
      
      return joinedEvents
    } catch (err: any) {
      if (err.code === 'ENOENT') {
        return []
      }
      throw err
    }
  } catch (err: any) {
    console.error('Error reading joined events:', err)
    setResponseStatus(event, 500)
    return { message: 'Failed to read events' }
  }
})
