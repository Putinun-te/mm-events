import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useAuth } from '~/composables/useAuth'

describe('useAuth Composable', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    vi.clearAllMocks()
    localStorage.clear()
    sessionStorage.clear()
    // Reset composable state
    const { logout } = useAuth()
    logout()
  })

  describe('Authentication State', () => {
    it('should initialize with not logged in state', () => {
      const { isLoggedIn } = useAuth()
      expect(isLoggedIn.value).toBe(false)
    })

    it('should detect token in localStorage', () => {
      localStorage.setItem('jwt_token', 'test-token')
      const { loadFromStorage, isLoggedIn } = useAuth()
      loadFromStorage()
      expect(isLoggedIn.value).toBe(true)
    })

    it('should detect token in sessionStorage', () => {
      sessionStorage.setItem('jwt_token', 'session-token')
      const { loadFromStorage, isLoggedIn } = useAuth()
      loadFromStorage()
      expect(isLoggedIn.value).toBe(true)
    })

    it('should prefer localStorage over sessionStorage', () => {
      localStorage.setItem('jwt_token', 'local-token')
      sessionStorage.setItem('jwt_token', 'session-token')
      const { loadFromStorage, getToken } = useAuth()
      loadFromStorage()
      expect(getToken()).toBe('local-token')
    })
  })

  describe('Token Management', () => {
    it('should store token correctly', () => {
      const { setToken } = useAuth()
      setToken('new-token', false)
      expect(localStorage.getItem('jwt_token')).toBe('new-token')
    })

    it('should store token in sessionStorage when remember is true', () => {
      const { setToken } = useAuth()
      setToken('session-token', true)
      expect(sessionStorage.getItem('jwt_token')).toBe('session-token')
    })

    it('should retrieve stored token', () => {
      localStorage.setItem('jwt_token', 'stored-token')
      const { getToken } = useAuth()
      expect(getToken()).toBe('stored-token')
    })

    it('should return null when no token exists', () => {
      const { getToken } = useAuth()
      expect(getToken()).toBeNull()
    })
  })

  describe('Logout', () => {
    it('should clear token from localStorage', () => {
      localStorage.setItem('jwt_token', 'token-to-clear')
      const { logout, isLoggedIn } = useAuth()
      logout()
      expect(localStorage.getItem('jwt_token')).toBeNull()
      expect(isLoggedIn.value).toBe(false)
    })

    it('should clear token from sessionStorage', () => {
      sessionStorage.setItem('jwt_token', 'session-token-to-clear')
      const { logout } = useAuth()
      logout()
      expect(sessionStorage.getItem('jwt_token')).toBeNull()
    })

    it('should clear profile data on logout', () => {
      localStorage.setItem('profile_data', JSON.stringify({ name: 'Test' }))
      const { logout } = useAuth()
      logout()
      expect(localStorage.getItem('profile_data')).toBeNull()
    })
  })

  describe('Profile Management', () => {
    it('should save profile data', () => {
      const { setProfile } = useAuth()
      const profileData = { username: 'testuser', email: 'test@test.com' }
      setProfile(profileData)
      expect(localStorage.getItem('profile_data')).toBe(JSON.stringify(profileData))
    })

    it('should retrieve profile data', () => {
      const profileData = { username: 'testuser', email: 'test@test.com' }
      localStorage.setItem('profile_data', JSON.stringify(profileData))
      const { getProfile } = useAuth()
      expect(getProfile()).toEqual(profileData)
    })

    it('should return null for invalid profile data', () => {
      localStorage.setItem('profile_data', 'invalid-json')
      const { getProfile } = useAuth()
      expect(getProfile()).toBeNull()
    })
  })
})
