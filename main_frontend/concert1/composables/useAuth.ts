import { ref, computed } from 'vue'

// Singleton state - shared across all instances
let token = ref<string | null>(null)
let profile = ref<any>(null)

export function useAuth() {
  const isLoggedIn = computed(() => !!token.value)

  const loadFromStorage = () => {
    const localToken = localStorage.getItem('jwt_token')
    const sessionToken = sessionStorage.getItem('jwt_token')
    token.value = localToken || sessionToken || null
    
    if (token.value) {
      const savedProfile = localStorage.getItem('profile_data')
      if (savedProfile) {
        try {
          profile.value = JSON.parse(savedProfile)
        } catch (e) {
          profile.value = null
        }
      }
    }
  }

  const setToken = (newToken: string, rememberMe: boolean = false) => {
    token.value = newToken
    if (rememberMe) {
      sessionStorage.setItem('jwt_token', newToken)
    } else {
      localStorage.setItem('jwt_token', newToken)
    }
  }

  const getToken = (): string | null => {
    return token.value || localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token') || null
  }

  const setProfile = (profileData: any) => {
    profile.value = profileData
    localStorage.setItem('profile_data', JSON.stringify(profileData))
  }

  const getProfile = (): any | null => {
    if (profile.value) return profile.value
    const savedProfile = localStorage.getItem('profile_data')
    if (!savedProfile) return null
    try {
      return JSON.parse(savedProfile)
    } catch (e) {
      return null
    }
  }

  const logout = () => {
    token.value = null
    profile.value = null
    localStorage.removeItem('jwt_token')
    sessionStorage.removeItem('jwt_token')
    localStorage.removeItem('profile_data')
    localStorage.removeItem('user_email')
    localStorage.removeItem('remember_me')
  }

  const saveAuth = (authData: { token: string; email?: string; username?: string }, rememberMe: boolean = false) => {
    setToken(authData.token, rememberMe)
    if (authData.email || authData.username) {
      setProfile({
        email: authData.email,
        username: authData.username
      })
    }
    if (authData.email) {
      localStorage.setItem('user_email', authData.email)
    }
    localStorage.setItem('remember_me', rememberMe.toString())
  }

  const shouldCompleteProfile = (): boolean => {
    const profileData = getProfile()
    // Check if profile is incomplete (missing name, phone, etc.)
    return !profileData || !profileData.firstName || !profileData.lastName
  }

  return {
    isLoggedIn,
    token,
    profile,
    loadFromStorage,
    setToken,
    getToken,
    setProfile,
    getProfile,
    logout,
    saveAuth,
    shouldCompleteProfile
  }
}
