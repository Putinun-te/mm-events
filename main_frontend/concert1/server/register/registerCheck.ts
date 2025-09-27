import axios from "axios";

const BASE_URL = process.env.BACKEND_BASE_URL || "http://localhost:8080";
const API_URL = `${BASE_URL}/registerCheck`;

type user = {
    name: string,
    email: string,
    password: string
}
// export const registerCheck = async (user: { name: string; email: string; password: string }) => {
export const registerCheck = async (): Promise<user[]> => {
  try {
    const response = await axios.get(`${API_URL}/register`);
    return response.data;
  } catch (error) {
    console.error("Registration failed:", error);
    throw error;
  }
};