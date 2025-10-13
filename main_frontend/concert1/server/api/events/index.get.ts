import type { H3Event } from 'h3'

export default defineEventHandler(async (event: H3Event) => {
  const query = getQuery(event)
  const page = Number(query.page ?? 0)
  const size = Number(query.size ?? 12)

  const config = useRuntimeConfig()
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080'

  const url = new URL('/api/events', backend)
  url.searchParams.set('page', page.toString())
  url.searchParams.set('size', size.toString())

  return await $fetch(url.toString(), { method: 'GET' })
})
