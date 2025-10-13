import type { H3Event } from 'h3'

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  const config = useRuntimeConfig();
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080';
  const auth = getRequestHeader(event, 'authorization') || ''
  try {
    const res: any = await $fetch(`${backend}/api/auth/me`, {
      headers: { Authorization: auth }
    });
    return res;
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500;
    setResponseStatus(event, status);
    const message = err?.data?.message || err?.response?._data?.message || err?.message || 'Fetch user failed';
    return { message };
  }
});
