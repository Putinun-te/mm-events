import { ref, computed } from 'vue'
import { useRuntimeConfig } from 'nuxt/app'

export interface AuthUser { username?: string; email?: string; token?: string }

// everything a login stores; cleared together
const SESSION_KEYS = ['jwt_token', 'refresh_token', 'user_email', 'username']

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
      // Always check localStorage first (Remember Me)
      let token = localStorage.getItem('jwt_token')
      let email = localStorage.getItem('user_email') || undefined
      let username = localStorage.getItem('username') || undefined
      const remembered = localStorage.getItem('remember_me') === 'true'
      
      if (token) {
        // User has Remember Me enabled
        user.value = { token, email, username }
        remember.value = true
        return
      }
      
      // Check sessionStorage (current session only)
      token = sessionStorage.getItem('jwt_token')
      email = sessionStorage.getItem('user_email') || undefined
      username = sessionStorage.getItem('username') || undefined
      
      if (token) {
        user.value = { token, email, username }
        remember.value = false
      }
    } catch {}
  }

  function saveAuth(payload: { token: string; refreshToken?: string; email?: string; username?: string }, rememberMe: boolean) {
    // clear old values
    for (const store of [localStorage, sessionStorage]) {
      for (const key of SESSION_KEYS) store.removeItem(key)
    }

    const storage: Storage = rememberMe ? localStorage : sessionStorage
    storage.setItem('jwt_token', payload.token)
    // the refresh token lives next to the access token, so "Remember me" keeps both
    if (payload.refreshToken) storage.setItem('refresh_token', payload.refreshToken)
    if (payload.email) storage.setItem('user_email', payload.email)
    if (payload.username) storage.setItem('username', payload.username)
    if (rememberMe) localStorage.setItem('remember_me', 'true')
    else localStorage.removeItem('remember_me')

    user.value = { token: payload.token, email: payload.email, username: payload.username }
  }

  function clearAuth() {
    for (const store of [localStorage, sessionStorage]) {
      for (const key of SESSION_KEYS) store.removeItem(key)
    }
    localStorage.removeItem('remember_me')
    user.value = null
  }

  /**
   * Logs out here and on the server: the backend revokes the access token and the
   * refresh token, so a copy of either (another tab, a leaked value) stops working too.
   * The refresh token is enough on its own, which matters when the access token has
   * already expired. Local logout never waits for the network and still happens if
   * the request fails.
   */
  function logout() {
    // storage first: it holds the newest access token after a refresh
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token') || user.value?.token
    const refreshToken = localStorage.getItem('refresh_token') || sessionStorage.getItem('refresh_token')
    clearAuth()
    if (!token && !refreshToken) return
    const headers: Record<string, string> = { 'Content-Type': 'application/json' }
    if (token) headers.Authorization = `Bearer ${token}`
    const baseURL = useRuntimeConfig().public.backendBaseUrl
    fetch(`${baseURL}/api/auth/logout`, {
      method: 'POST',
      headers,
      body: JSON.stringify(refreshToken ? { refreshToken } : {}),
      keepalive: true
    }).catch(() => {})
  }

  function shouldCompleteProfile(): boolean {
    return localStorage.getItem('profile_completed') !== 'true'
  }

  return { user, remember, isLoggedIn, loadFromStorage, saveAuth, clearAuth, logout, shouldCompleteProfile }
}
