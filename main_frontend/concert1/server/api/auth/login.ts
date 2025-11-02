import type { H3Event } from 'h3'
import { buildBackendUrl } from '../../utils/backend'

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  // Accept only POST for login, return 405 otherwise
  if (getMethod(event).toUpperCase() !== 'POST') {
    setResponseStatus(event, 405)
    return { message: 'Method Not Allowed' }
  }
  const body = await readBody(event);
  const config = useRuntimeConfig();
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080';
  try {
  const res: any = await $fetch(buildBackendUrl(backend, '/api/auth/login'), {
      method: 'POST',
      body,
    });
    return res;
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500;
    setResponseStatus(event, status);
    const message = err?.data?.message || err?.response?._data?.message || err?.message || 'Login failed';
    return { message };
  }
});
