import type { H3Event } from 'h3'
import { buildBackendUrl } from '../../utils/backend'

export default defineEventHandler(async (event: H3Event): Promise<any> => {
  // Temporarily disable this endpoint to prevent authentication errors
  setResponseStatus(event, 501);
  return { message: 'Endpoint temporarily disabled' };
});
