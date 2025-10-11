import axios from "axios";

const BASE_URL = process.env.BACKEND_BASE_URL || "http://localhost:8080";
const API_URL = `${BASE_URL}/api/auth`;

// let data = [{'abc': '123'}, {'testing': '123'}]

export const login = async (credentials: { usernameOrEmail: string; password: string }) => {
  try {
    const response = await axios.post(`${API_URL}/login`, credentials);
    return response.data;
  } catch (error) {
    console.error("Login failed:", error);
    throw error;
  }
};

export const getCurrentUser = async (token: string) => {
  try {
    const response = await axios.get(`${API_URL}/me`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    return response.data;
  } catch (error) {
    console.error("Get current user failed:", error);
    throw error;
  }
};