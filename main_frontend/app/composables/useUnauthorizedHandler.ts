/**
 * Unauthorized Handler Composable
 * Handles 401/403 responses from API calls (not middleware redirects)
 */

import { useRouter } from 'vue-router'
import { useToast } from './useToast'
import { useAuth } from './useAuth'

export const useUnauthorizedHandler = () => {
  const router = useRouter()
  const { error: showError } = useToast()
  const { clearAuth } = useAuth()

  /**
   * Handle unauthorized response (401/403) from API calls
   * Only shows error message for actual API failures, not initial page loads
   */
  const handleUnauthorized = (errorMessage?: string, currentPath?: string, showMessage: boolean = true) => {
    // Clear authentication data
    clearAuth()

    // Show error message only if requested (for API call failures)
    if (showMessage) {
      const message = errorMessage || 'Your session has expired. Please login again.'
      showError(message, 'Authentication Required')
    }

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
   * Shows error message since this is an API call failure
   */
  const handleApiError = (error: any, currentPath?: string) => {
    if (isUnauthorizedError(error)) {
      const message = error?.statusMessage || error?.message || error?.data?.message
      handleUnauthorized(message, currentPath, true) // Show message for API errors
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
