import { setHeader } from 'h3'
import type { H3Event } from 'h3'
import { buildBackendUrl } from '../../utils/backend'

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  const method = getMethod(event).toUpperCase()

  if (method === 'OPTIONS') {
    setHeader(event, 'Allow', 'PUT, POST, OPTIONS')
    setResponseStatus(event, 204)
    return null
  }

  if (!['PUT', 'POST', 'PATCH'].includes(method)) {
    setHeader(event, 'Allow', 'PUT, POST, PATCH, OPTIONS')
    setResponseStatus(event, 405)
    return { message: 'Method Not Allowed' }
  }

  const body = await readBody(event);
  const config = useRuntimeConfig();
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080';
  const auth = getRequestHeader(event, 'authorization') || ''
  try {
  const res: any = await $fetch(buildBackendUrl(backend, '/api/users/me'), {
      method: 'PUT',
      body,
      headers: { Authorization: auth }
    });
    return res;
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500;
    setResponseStatus(event, status);
    const message = err?.data?.message || err?.response?._data?.message || err?.message || 'Update failed';
    return { message };
  }
});
