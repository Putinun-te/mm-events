// Authentication composable for managing user state
import { ref, computed, readonly } from 'vue'

const user = ref<any>(null)
const token = ref<string | null>(null)

export const useAuth = () => {
  // Initialize from localStorage if available (client-side only)
  if (typeof window !== 'undefined') {
    const storedToken = localStorage.getItem('jwt_token')
    const storedUsername = localStorage.getItem('username')
    const storedEmail = localStorage.getItem('user_email')
    
    if (storedToken && storedUsername && storedEmail) {
      token.value = storedToken
      user.value = {
        username: storedUsername,
        email: storedEmail
      }
    }
  }

  const isAuthenticated = computed(() => !!token.value)

  const setAuth = (authData: any) => {
    user.value = {
      username: authData.username,
      email: authData.email
    }
    token.value = authData.token
    
    if (typeof window !== 'undefined') {
      localStorage.setItem('jwt_token', authData.token)
      localStorage.setItem('username', authData.username)
      localStorage.setItem('user_email', authData.email)
    }
  }

  const clearAuth = () => {
    user.value = null
    token.value = null
    
    if (typeof window !== 'undefined') {
      localStorage.removeItem('jwt_token')
      localStorage.removeItem('username')
      localStorage.removeItem('user_email')
    }
  }

  const logout = () => {
    clearAuth()
    // Redirect to login page or home
    if (typeof window !== 'undefined') {
      window.location.href = '/concert/'
    }
  }

  return {
    user: readonly(user),
    token: readonly(token),
    isAuthenticated,
    setAuth,
    clearAuth,
    logout
  }
}
