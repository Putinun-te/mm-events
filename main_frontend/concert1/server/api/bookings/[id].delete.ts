import type { H3Event } from 'h3'

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
    const response = await fetch(`${backend}/api/bookings/${bookingId}`, {
      method: 'DELETE',
      headers: { Authorization: token }
    })
    
    if (!response.ok) {
      throw createError({ 
        statusCode: response.status, 
        statusMessage: `Failed to cancel booking: ${response.statusText}` 
      })
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
