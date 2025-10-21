import type { H3Event } from 'h3'

export default defineEventHandler(async (event: H3Event) => {
  const body = await readBody(event)
  const config = useRuntimeConfig()
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'

  const token = getHeader(event, 'authorization')
  if (!token) {
    throw createError({ statusCode: 401, statusMessage: 'Authorization header missing' })
  }

  try {
    return await $fetch(`${backend}/api/bookings`, {
      method: 'POST',
      body,
      headers: { Authorization: token }
    })
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500
    const message = err?.data?.message || err?.response?._data?.message || err?.message || 'Failed to create booking'
    throw createError({ statusCode: status, statusMessage: message })
  }
})
