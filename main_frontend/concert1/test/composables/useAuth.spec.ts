import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { useAuth } from '@/composables/useAuth'

describe('useAuth', () => {
  beforeEach(() => {
    // Clear all storage before each test
    localStorage.clear()
    sessionStorage.clear()
  })

  afterEach(() => {
    // Clean up after each test
    localStorage.clear()
    sessionStorage.clear()
  })

  it('initializes with no user logged in', () => {
    const { user, isLoggedIn } = useAuth()
    
    expect(user.value).toBeNull()
    expect(isLoggedIn.value).toBe(false)
  })

  it('saves auth to localStorage when rememberMe is true', () => {
    const { saveAuth, user, isLoggedIn } = useAuth()
    
    const payload = {
      token: 'test-jwt-token-123',
      email: 'test@example.com',
      username: 'testuser'
    }
    
    saveAuth(payload, true)
    
    // Check localStorage
    expect(localStorage.getItem('jwt_token')).toBe('test-jwt-token-123')
    expect(localStorage.getItem('user_email')).toBe('test@example.com')
    expect(localStorage.getItem('username')).toBe('testuser')
    expect(localStorage.getItem('remember_me')).toBe('true')
    
    // Check sessionStorage is empty
    expect(sessionStorage.getItem('jwt_token')).toBeNull()
    
    // Check reactive state
    expect(user.value?.token).toBe('test-jwt-token-123')
    expect(user.value?.email).toBe('test@example.com')
    expect(user.value?.username).toBe('testuser')
    expect(isLoggedIn.value).toBe(true)
  })

  it('saves auth to sessionStorage when rememberMe is false', () => {
    const { saveAuth, user, isLoggedIn } = useAuth()
    
    const payload = {
      token: 'session-token-456',
      email: 'session@example.com',
      username: 'sessionuser'
    }
    
    saveAuth(payload, false)
    
    // Check sessionStorage
    expect(sessionStorage.getItem('jwt_token')).toBe('session-token-456')
    expect(sessionStorage.getItem('user_email')).toBe('session@example.com')
    expect(sessionStorage.getItem('username')).toBe('sessionuser')
    
    // Check localStorage doesn't have auth data
    expect(localStorage.getItem('jwt_token')).toBeNull()
    expect(localStorage.getItem('remember_me')).toBeNull()
    
    // Check reactive state
    expect(user.value?.token).toBe('session-token-456')
    expect(isLoggedIn.value).toBe(true)
  })

  it('loads auth from localStorage on loadFromStorage', () => {
    // Pre-populate localStorage
    localStorage.setItem('jwt_token', 'stored-token-789')
    localStorage.setItem('user_email', 'stored@example.com')
    localStorage.setItem('username', 'storeduser')
    localStorage.setItem('remember_me', 'true')
    
    const { loadFromStorage, user, isLoggedIn, remember } = useAuth()
    
    loadFromStorage()
    
    expect(user.value?.token).toBe('stored-token-789')
    expect(user.value?.email).toBe('stored@example.com')
    expect(user.value?.username).toBe('storeduser')
    expect(remember.value).toBe(true)
    expect(isLoggedIn.value).toBe(true)
  })

  it('loads auth from sessionStorage when localStorage is empty', () => {
    // Pre-populate sessionStorage only
    sessionStorage.setItem('jwt_token', 'session-stored-token')
    sessionStorage.setItem('user_email', 'session-stored@example.com')
    sessionStorage.setItem('username', 'sessionstored')
    
    const { loadFromStorage, user, isLoggedIn, remember } = useAuth()
    
    loadFromStorage()
    
    expect(user.value?.token).toBe('session-stored-token')
    expect(user.value?.email).toBe('session-stored@example.com')
    expect(user.value?.username).toBe('sessionstored')
    expect(remember.value).toBe(false)
    expect(isLoggedIn.value).toBe(true)
  })

  it('prefers localStorage over sessionStorage when both exist', () => {
    // Populate both storages
    localStorage.setItem('jwt_token', 'local-token')
    localStorage.setItem('user_email', 'local@example.com')
    sessionStorage.setItem('jwt_token', 'session-token')
    sessionStorage.setItem('user_email', 'session@example.com')
    
    const { loadFromStorage, user } = useAuth()
    
    loadFromStorage()
    
    // Should load from localStorage (first priority)
    expect(user.value?.token).toBe('local-token')
    expect(user.value?.email).toBe('local@example.com')
  })

  it('clears all auth data on clearAuth', () => {
    // Setup auth in both storages
    localStorage.setItem('jwt_token', 'token-to-clear')
    localStorage.setItem('user_email', 'email-to-clear')
    localStorage.setItem('username', 'username-to-clear')
    localStorage.setItem('remember_me', 'true')
    sessionStorage.setItem('jwt_token', 'session-token-to-clear')
    sessionStorage.setItem('user_email', 'session-email-to-clear')
    
    const { clearAuth, user, isLoggedIn } = useAuth()
    
    // Load first
    const { loadFromStorage } = useAuth()
    loadFromStorage()
    
    // Then clear
    clearAuth()
    
    // Check all storages are empty
    expect(localStorage.getItem('jwt_token')).toBeNull()
    expect(localStorage.getItem('user_email')).toBeNull()
    expect(localStorage.getItem('username')).toBeNull()
    expect(localStorage.getItem('remember_me')).toBeNull()
    expect(sessionStorage.getItem('jwt_token')).toBeNull()
    expect(sessionStorage.getItem('user_email')).toBeNull()
    expect(sessionStorage.getItem('username')).toBeNull()
    
    // Check reactive state
    expect(user.value).toBeNull()
    expect(isLoggedIn.value).toBe(false)
  })

  it('clears old storage data when switching between remember modes', () => {
    const { saveAuth } = useAuth()
    
    // First save to localStorage (remember = true)
    saveAuth({ token: 'token1', email: 'email1@example.com' }, true)
    expect(localStorage.getItem('jwt_token')).toBe('token1')
    expect(sessionStorage.getItem('jwt_token')).toBeNull()
    
    // Then save to sessionStorage (remember = false)
    saveAuth({ token: 'token2', email: 'email2@example.com' }, false)
    
    // Old localStorage data should be cleared
    expect(localStorage.getItem('jwt_token')).toBeNull()
    expect(localStorage.getItem('user_email')).toBeNull()
    expect(localStorage.getItem('remember_me')).toBeNull()
    
    // New sessionStorage data should exist
    expect(sessionStorage.getItem('jwt_token')).toBe('token2')
    expect(sessionStorage.getItem('user_email')).toBe('email2@example.com')
  })

  it('returns true for shouldCompleteProfile when not completed', () => {
    const { shouldCompleteProfile } = useAuth()
    
    expect(shouldCompleteProfile()).toBe(true)
  })

  it('returns false for shouldCompleteProfile when profile is completed', () => {
    localStorage.setItem('profile_completed', 'true')
    
    const { shouldCompleteProfile } = useAuth()
    
    expect(shouldCompleteProfile()).toBe(false)
  })

  it('handles missing optional fields in saveAuth', () => {
    const { saveAuth, user } = useAuth()
    
    // Save with only token (no email/username)
    saveAuth({ token: 'token-only' }, false)
    
    expect(sessionStorage.getItem('jwt_token')).toBe('token-only')
    expect(sessionStorage.getItem('user_email')).toBeNull()
    expect(sessionStorage.getItem('username')).toBeNull()
    expect(user.value?.token).toBe('token-only')
    expect(user.value?.email).toBeUndefined()
    expect(user.value?.username).toBeUndefined()
  })

  it('handles loadFromStorage with missing data gracefully', () => {
    // Clear state first
    const { clearAuth } = useAuth()
    clearAuth()
    
    // No data in storage
    const { loadFromStorage, user, isLoggedIn } = useAuth()
    
    loadFromStorage()
    
    expect(user.value).toBeNull()
    expect(isLoggedIn.value).toBe(false)
  })

  it('handles loadFromStorage with partial data', () => {
    // Only token, no email/username
    localStorage.setItem('jwt_token', 'partial-token')
    
    const { loadFromStorage, user, isLoggedIn } = useAuth()
    
    loadFromStorage()
    
    expect(user.value?.token).toBe('partial-token')
    expect(user.value?.email).toBeUndefined()
    expect(user.value?.username).toBeUndefined()
    expect(isLoggedIn.value).toBe(true)
  })

  it('maintains reactive state across multiple operations', () => {
    const { saveAuth, clearAuth, user, isLoggedIn } = useAuth()
    
    // Clear state first to ensure clean start
    clearAuth()
    
    // Initial state
    expect(isLoggedIn.value).toBe(false)
    
    // Save auth
    saveAuth({ token: 'reactive-token', email: 'reactive@example.com' }, true)
    expect(isLoggedIn.value).toBe(true)
    expect(user.value?.token).toBe('reactive-token')
    
    // Clear auth
    clearAuth()
    expect(isLoggedIn.value).toBe(false)
    expect(user.value).toBeNull()
    
    // Save again
    saveAuth({ token: 'reactive-token-2' }, false)
    expect(isLoggedIn.value).toBe(true)
    expect(user.value?.token).toBe('reactive-token-2')
  })
})
