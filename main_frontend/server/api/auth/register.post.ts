import type { H3Event } from 'h3'

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  const body = await readBody(event);
  const config = useRuntimeConfig();
  const backend = (config.public as any)?.backendBaseUrl || process.env.BACKEND_BASE_URL || 'http://localhost:8080';
  try {
    const res: any = await $fetch(`${backend}/api/auth/register`, {
      method: 'POST',
      body,
    });
    return res;
  } catch (err: any) {
    const status = err?.response?.status || err?.status || 500;
    setResponseStatus(event, status);
    const data = err?.data || err?.response?._data || {};
    let message: string | undefined = data?.message || err?.message;
    // Try to extract validation errors from common Spring formats
    if (!message) {
      const errors = (data?.errors || []) as any[];
      if (Array.isArray(errors) && errors.length) {
        const first = errors[0];
        // errors may be array of strings or objects with defaultMessage/message
        message = typeof first === 'string' ? first : (first?.defaultMessage || first?.message || undefined);
        if (!message) {
          message = errors.map((e: any) => (typeof e === 'string' ? e : (e?.defaultMessage || e?.message))).filter(Boolean).join(', ');
        }
      }
    }
    return { message: message || 'Registration failed' };
  }
});
