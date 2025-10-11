import axios from "axios";

const BASE_URL = process.env.BACKEND_BASE_URL || "http://localhost:8080";
const API_URL = `${BASE_URL}/api/auth`;

export const register = async (user: { username: string; email: string; password: string }) => {
  try {
    const response = await axios.post(`${API_URL}/register`, user);
    return response.data;
  } catch (error) {
    console.error("Registration failed:", error);
    throw error;
  }
};
