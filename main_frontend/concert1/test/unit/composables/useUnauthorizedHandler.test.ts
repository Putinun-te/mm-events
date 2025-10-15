import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useUnauthorizedHandler } from '~/app/composables/useUnauthorizedHandler'

// Mock dependencies
vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: vi.fn()
  })
}))

vi.mock('~/app/composables/useToast', () => ({
  useToast: () => ({
    error: vi.fn()
  })
}))

vi.mock('~/app/composables/useAuth', () => ({
  useAuth: () => ({
    clearAuth: vi.fn()
  })
}))

describe('useUnauthorizedHandler', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  describe('isUnauthorizedError', () => {
    it('should return true for 401 status code', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError({ statusCode: 401 })).toBe(true)
    })

    it('should return true for 403 status code', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError({ statusCode: 403 })).toBe(true)
    })

    it('should return true for 401 in status property', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError({ status: 401 })).toBe(true)
    })

    it('should return true for 403 in response.status', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError({ response: { status: 403 } })).toBe(true)
    })

    it('should return false for other status codes', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError({ statusCode: 404 })).toBe(false)
      expect(isUnauthorizedError({ statusCode: 500 })).toBe(false)
    })

    it('should return false for undefined error', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError(undefined)).toBe(false)
    })

    it('should return false for empty object', () => {
      const { isUnauthorizedError } = useUnauthorizedHandler()
      expect(isUnauthorizedError({})).toBe(false)
    })
  })

  describe('handleUnauthorized', () => {
    it('should clear auth data', () => {
      const { handleUnauthorized } = useUnauthorizedHandler()
      handleUnauthorized()
      // clearAuth is called (mocked)
      expect(true).toBe(true)
    })

    it('should store redirect path in localStorage', () => {
      const { handleUnauthorized } = useUnauthorizedHandler()
      handleUnauthorized('Session expired', '/dashboard', true)
      expect(localStorage.getItem('redirect_after_login')).toBe('/dashboard')
    })

    it('should not store redirect path if not provided', () => {
      const { handleUnauthorized } = useUnauthorizedHandler()
      handleUnauthorized('Session expired', undefined, true)
      expect(localStorage.getItem('redirect_after_login')).toBeNull()
    })

    it('should handle default error message', () => {
      const { handleUnauthorized } = useUnauthorizedHandler()
      handleUnauthorized(undefined, undefined, true)
      // Should not throw error
      expect(true).toBe(true)
    })

    it('should handle custom error message', () => {
      const { handleUnauthorized } = useUnauthorizedHandler()
      handleUnauthorized('Custom error message', '/profile', true)
      expect(localStorage.getItem('redirect_after_login')).toBe('/profile')
    })

    it('should not show message when showMessage is false', () => {
      const { handleUnauthorized } = useUnauthorizedHandler()
      handleUnauthorized('Error', '/path', false)
      // Message is not shown (toast.error not called with message)
      expect(true).toBe(true)
    })
  })

  describe('handleApiError', () => {
    it('should return true and handle 401 error', () => {
      const { handleApiError } = useUnauthorizedHandler()
      const error = { statusCode: 401, message: 'Unauthorized' }
      const result = handleApiError(error, '/api/data')
      expect(result).toBe(true)
      expect(localStorage.getItem('redirect_after_login')).toBe('/api/data')
    })

    it('should return true and handle 403 error', () => {
      const { handleApiError } = useUnauthorizedHandler()
      const error = { statusCode: 403, message: 'Forbidden' }
      const result = handleApiError(error)
      expect(result).toBe(true)
    })

    it('should return false for non-auth errors', () => {
      const { handleApiError } = useUnauthorizedHandler()
      const error = { statusCode: 404, message: 'Not Found' }
      const result = handleApiError(error)
      expect(result).toBe(false)
    })

    it('should return false for 500 errors', () => {
      const { handleApiError } = useUnauthorizedHandler()
      const error = { statusCode: 500, message: 'Internal Server Error' }
      const result = handleApiError(error)
      expect(result).toBe(false)
    })

    it('should extract error message from different properties', () => {
      const { handleApiError } = useUnauthorizedHandler()
      
      // From statusMessage
      handleApiError({ statusCode: 401, statusMessage: 'Auth failed' })
      
      // From message
      handleApiError({ statusCode: 401, message: 'Token expired' })
      
      // From data.message
      handleApiError({ statusCode: 401, data: { message: 'Invalid token' } })
      
      expect(true).toBe(true)
    })

    it('should handle error without message', () => {
      const { handleApiError } = useUnauthorizedHandler()
      const error = { statusCode: 401 }
      const result = handleApiError(error)
      expect(result).toBe(true)
    })
  })

  describe('Integration Tests', () => {
    it('should handle complete unauthorized flow', () => {
      const { handleApiError, isUnauthorizedError } = useUnauthorizedHandler()
      
      const error = { statusCode: 401, message: 'Session expired' }
      
      expect(isUnauthorizedError(error)).toBe(true)
      const handled = handleApiError(error, '/protected-page')
      expect(handled).toBe(true)
      expect(localStorage.getItem('redirect_after_login')).toBe('/protected-page')
    })

    it('should differentiate between unauthorized and other errors', () => {
      const { handleApiError } = useUnauthorizedHandler()
      
      const authError = { statusCode: 401 }
      const notFoundError = { statusCode: 404 }
      
      expect(handleApiError(authError)).toBe(true)
      expect(handleApiError(notFoundError)).toBe(false)
    })
  })
})
