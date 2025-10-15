import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useAuth } from '~/app/composables/useAuth'

describe('app/composables/useAuth', () => {
  beforeEach(() => {
    localStorage.clear()
    sessionStorage.clear()
    vi.clearAllMocks()
    
    // Clear auth state
    const { clearAuth } = useAuth()
    clearAuth()
  })

  describe('Initial State', () => {
    it('should initialize with logged out state', () => {
      const { isLoggedIn } = useAuth()
      expect(isLoggedIn.value).toBe(false)
    })

    it('should have null user initially', () => {
      const { user } = useAuth()
      expect(user.value).toBeNull()
    })

    it('should have remember set to false initially', () => {
      const { remember } = useAuth()
      expect(remember.value).toBe(false)
    })
  })

  describe('loadFromStorage', () => {
    it('should load from localStorage when remember_me is true', () => {
      localStorage.setItem('remember_me', 'true')
      localStorage.setItem('jwt_token', 'test-token')
      localStorage.setItem('user_email', 'test@example.com')
      localStorage.setItem('username', 'testuser')

      const { loadFromStorage, user, remember, isLoggedIn } = useAuth()
      loadFromStorage()

      expect(user.value?.token).toBe('test-token')
      expect(user.value?.email).toBe('test@example.com')
      expect(user.value?.username).toBe('testuser')
      expect(remember.value).toBe(true)
      expect(isLoggedIn.value).toBe(true)
    })

    it('should load from sessionStorage when remember_me is not set', () => {
      sessionStorage.setItem('jwt_token', 'session-token')
      sessionStorage.setItem('user_email', 'session@example.com')
      sessionStorage.setItem('username', 'sessionuser')

      const { loadFromStorage, user, remember, isLoggedIn } = useAuth()
      loadFromStorage()

      expect(user.value?.token).toBe('session-token')
      expect(user.value?.email).toBe('session@example.com')
      expect(user.value?.username).toBe('sessionuser')
      expect(remember.value).toBe(false)
      expect(isLoggedIn.value).toBe(true)
    })

    it('should handle missing token gracefully', () => {
      localStorage.setItem('remember_me', 'true')
      localStorage.setItem('user_email', 'test@example.com')
      
      const { loadFromStorage, user } = useAuth()
      loadFromStorage()

      // Without token, user should still be null even with other data
      expect(user.value).toBeNull()
    })

    it('should handle errors gracefully', () => {
      vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
        throw new Error('Storage error')
      })

      const { loadFromStorage } = useAuth()
      expect(() => loadFromStorage()).not.toThrow()
    })
  })

  describe('saveAuth', () => {
    it('should save to localStorage when rememberMe is true', () => {
      const { saveAuth, user, isLoggedIn } = useAuth()
      saveAuth({ token: 'new-token', email: 'new@example.com', username: 'newuser' }, true)

      expect(localStorage.getItem('jwt_token')).toBe('new-token')
      expect(localStorage.getItem('user_email')).toBe('new@example.com')
      expect(localStorage.getItem('username')).toBe('newuser')
      expect(localStorage.getItem('remember_me')).toBe('true')
      expect(user.value?.token).toBe('new-token')
      expect(isLoggedIn.value).toBe(true)
    })

    it('should save to sessionStorage when rememberMe is false', () => {
      const { saveAuth, user } = useAuth()
      saveAuth({ token: 'session-token', email: 'session@example.com', username: 'sessionuser' }, false)

      expect(sessionStorage.getItem('jwt_token')).toBe('session-token')
      expect(sessionStorage.getItem('user_email')).toBe('session@example.com')
      expect(sessionStorage.getItem('username')).toBe('sessionuser')
      expect(localStorage.getItem('remember_me')).toBeNull()
      expect(user.value?.token).toBe('session-token')
    })

    it('should clear old storage before saving', () => {
      localStorage.setItem('jwt_token', 'old-local-token')
      sessionStorage.setItem('jwt_token', 'old-session-token')

      const { saveAuth } = useAuth()
      saveAuth({ token: 'new-token' }, true)

      expect(sessionStorage.getItem('jwt_token')).toBeNull()
      expect(localStorage.getItem('jwt_token')).toBe('new-token')
    })

    it('should handle payload without email and username', () => {
      const { saveAuth, user } = useAuth()
      saveAuth({ token: 'token-only' }, true)

      expect(user.value?.token).toBe('token-only')
      expect(user.value?.email).toBeUndefined()
      expect(user.value?.username).toBeUndefined()
    })
  })

  describe('clearAuth', () => {
    it('should clear all storage and user data', () => {
      localStorage.setItem('jwt_token', 'token')
      localStorage.setItem('user_email', 'email@example.com')
      localStorage.setItem('username', 'username')
      localStorage.setItem('remember_me', 'true')
      sessionStorage.setItem('jwt_token', 'session-token')

      const { clearAuth, user, isLoggedIn } = useAuth()
      clearAuth()

      expect(localStorage.getItem('jwt_token')).toBeNull()
      expect(localStorage.getItem('user_email')).toBeNull()
      expect(localStorage.getItem('username')).toBeNull()
      expect(localStorage.getItem('remember_me')).toBeNull()
      expect(sessionStorage.getItem('jwt_token')).toBeNull()
      expect(user.value).toBeNull()
      expect(isLoggedIn.value).toBe(false)
    })
  })

  describe('shouldCompleteProfile', () => {
    it('should return true when profile_completed is not set', () => {
      const { shouldCompleteProfile } = useAuth()
      expect(shouldCompleteProfile()).toBe(true)
    })

    it('should return false when profile_completed is true', () => {
      localStorage.setItem('profile_completed', 'true')
      const { shouldCompleteProfile } = useAuth()
      expect(shouldCompleteProfile()).toBe(false)
    })

    it('should return true when profile_completed is false', () => {
      localStorage.setItem('profile_completed', 'false')
      const { shouldCompleteProfile } = useAuth()
      expect(shouldCompleteProfile()).toBe(true)
    })
  })

  describe('Integration Tests', () => {
    it('should maintain state across multiple useAuth calls', () => {
      const auth1 = useAuth()
      auth1.saveAuth({ token: 'shared-token', email: 'shared@example.com' }, true)

      const auth2 = useAuth()
      expect(auth2.user.value?.token).toBe('shared-token')
      expect(auth2.isLoggedIn.value).toBe(true)
    })

    it('should complete full auth flow', () => {
      const { saveAuth, loadFromStorage, clearAuth, user, isLoggedIn } = useAuth()

      // Login
      saveAuth({ token: 'flow-token', email: 'flow@example.com', username: 'flowuser' }, true)
      expect(isLoggedIn.value).toBe(true)

      // Simulate page reload
      const auth2 = useAuth()
      auth2.loadFromStorage()
      expect(auth2.user.value?.token).toBe('flow-token')

      // Logout
      auth2.clearAuth()
      expect(auth2.isLoggedIn.value).toBe(false)
    })
  })
})
