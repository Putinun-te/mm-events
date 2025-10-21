import type { H3Event } from 'h3'
import { readFile } from 'fs/promises'
import { join } from 'path'

const JSON_FILE_PATH = join(process.cwd(), 'data', 'events.json')

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  const { id } = event.context.params || {}
  
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'Missing event id' })
  }

  try {
    const data = await readFile(JSON_FILE_PATH, 'utf-8')
    const events = JSON.parse(data)
    const foundEvent = events.find((e: any) => String(e.id) === String(id))
    
    if (!foundEvent) {
      setResponseStatus(event, 404)
      return { message: 'Event not found' }
    }
    
    return foundEvent
  } catch (err: any) {
    if (err.code === 'ENOENT') {
      setResponseStatus(event, 404)
      return { message: 'Event not found' }
    }
    console.error('Error reading event:', err)
    setResponseStatus(event, 500)
    return { message: 'Failed to read event' }
  }
})
