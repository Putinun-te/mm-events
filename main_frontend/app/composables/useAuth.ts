import { ref, computed } from 'vue'

export interface AuthUser { username?: string; email?: string; token?: string }

const user = ref<AuthUser | null>(null)
const remember = ref(false)

function readStorage(): { storage: Storage; remembered: boolean } {
  const remembered = localStorage.getItem('remember_me') === 'true'
  return { storage: remembered ? localStorage : sessionStorage, remembered }
}

export function useAuth() {
  const isLoggedIn = computed(() => !!user.value?.token)

  function loadFromStorage() {
    try {
      // Check if user chose "Remember Me" on their last login
      const remembered = localStorage.getItem('remember_me') === 'true'
      
      if (remembered) {
        // Load from localStorage (persistent)
        const token = localStorage.getItem('jwt_token')
        const email = localStorage.getItem('user_email') || undefined
        const username = localStorage.getItem('username') || undefined
        if (token) user.value = { token, email, username }
        remember.value = true
      } else {
        // Load from sessionStorage (cleared when browser closes)
        const token = sessionStorage.getItem('jwt_token')
        const email = sessionStorage.getItem('user_email') || undefined
        const username = sessionStorage.getItem('username') || undefined
        if (token) user.value = { token, email, username }
        remember.value = false
      }
    } catch {}
  }

  function saveAuth(payload: { token: string; email?: string; username?: string }, rememberMe: boolean) {
    // clear old values
    localStorage.removeItem('jwt_token'); localStorage.removeItem('user_email'); localStorage.removeItem('username')
    sessionStorage.removeItem('jwt_token'); sessionStorage.removeItem('user_email'); sessionStorage.removeItem('username')

    const storage: Storage = rememberMe ? localStorage : sessionStorage
    storage.setItem('jwt_token', payload.token)
    if (payload.email) storage.setItem('user_email', payload.email)
    if (payload.username) storage.setItem('username', payload.username)
    if (rememberMe) localStorage.setItem('remember_me', 'true')
    else localStorage.removeItem('remember_me')

    user.value = { token: payload.token, email: payload.email, username: payload.username }
  }

  function clearAuth() {
    localStorage.removeItem('jwt_token'); localStorage.removeItem('user_email'); localStorage.removeItem('username'); localStorage.removeItem('remember_me')
    sessionStorage.removeItem('jwt_token'); sessionStorage.removeItem('user_email'); sessionStorage.removeItem('username')
    user.value = null
  }

  function shouldCompleteProfile(): boolean {
    return localStorage.getItem('profile_completed') !== 'true'
  }

  return { user, remember, isLoggedIn, loadFromStorage, saveAuth, clearAuth, shouldCompleteProfile }
}
