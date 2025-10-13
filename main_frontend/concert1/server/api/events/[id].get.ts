import type { H3Event } from 'h3'

export default defineEventHandler(async (event: H3Event) => {
  const { id } = event.context.params || {}
  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'Missing event id' })
  }

  const config = useRuntimeConfig()
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'

  try {
    return await $fetch(`${backend}/api/events/${id}`, { method: 'GET' })
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500
    const message = err?.data?.message || err?.response?._data?.message || err?.message || 'Failed to fetch event'
    throw createError({ statusCode: status, statusMessage: message })
  }
})
