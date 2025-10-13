import axios from "axios";

export type AuthResponse = { token?: string; username?: string; email?: string; message?: string };

export const register = async (user: { username: string; email: string; password: string }): Promise<AuthResponse> => {
  // Call our Nuxt server proxy route
  const response = await axios.post<AuthResponse>(`/api/auth/register`, user);
  return response.data;
};
