/**
 * Unauthorized Handler Composable
 * Handles 401/403 responses globally when user is not authorized (logged out)
 */

import { useRouter } from 'vue-router'
import { useToast } from './useToast'
import { useAuth } from './useAuth'

export const useUnauthorizedHandler = () => {
  const router = useRouter()
  const { error: showError } = useToast()
  const { clearAuth } = useAuth()

  /**
   * Handle unauthorized response (401/403)
   * Clears authentication and redirects to login
   */
  const handleUnauthorized = (errorMessage?: string, currentPath?: string) => {
    // Clear authentication data
    clearAuth()

    // Show error message
    const message = errorMessage || 'Your session has expired. Please login again.'
    showError(message, 'Authentication Required')

    // Store the current path to redirect after login
    if (currentPath && typeof window !== 'undefined') {
      localStorage.setItem('redirect_after_login', currentPath)
    }

    // Redirect to login page
    if (typeof window !== 'undefined') {
      router.push('/LoginPage')
    }
  }

  /**
   * Check if error is unauthorized (401 or 403)
   */
  const isUnauthorizedError = (error: any): boolean => {
    const status = error?.statusCode || error?.status || error?.response?.status
    return status === 401 || status === 403
  }

  /**
   * Handle API error with automatic unauthorized detection
   */
  const handleApiError = (error: any, currentPath?: string) => {
    if (isUnauthorizedError(error)) {
      const message = error?.statusMessage || error?.message || error?.data?.message
      handleUnauthorized(message, currentPath)
      return true
    }
    return false
  }

  return {
    handleUnauthorized,
    isUnauthorizedError,
    handleApiError
  }
}
