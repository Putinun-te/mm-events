import axios from "axios";

export type AuthResponse = { token?: string; username?: string; email?: string; message?: string };

export const login = async (credentials: { usernameOrEmail: string; password: string }): Promise<AuthResponse> => {
  const response = await axios.post<AuthResponse>(`/api/auth/login`, credentials);
  return response.data;
};

export const getCurrentUser = async (token: string) => {
  const response = await axios.get(`/api/auth/me`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  return response.data;
};