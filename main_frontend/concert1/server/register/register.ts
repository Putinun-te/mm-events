import axios from "axios";

const API_URL = "http://localhost:8080/api/auth"; // your Spring Boot backend URL

export const register = async (user: { name: string; email: string; password: string }) => {
  try {
    const response = await axios.post(`${API_URL}/register`, user);
    return response.data;
  } catch (error) {
    console.error("Registration failed:", error);
    throw error;
  }
};
