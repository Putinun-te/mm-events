/**
 * Global Authentication Middleware
 * Automatically checks if user is authenticated for protected routes
 * Redirects to login page if user is not authorized (logged out)
 */

export default defineNuxtRouteMiddleware((to, from) => {
  // Skip middleware on server-side
  if (process.server) return

  // Protected routes that require authentication
  const protectedRoutes = [
    '/AccountPage',
    '/MyBookingsPage',
    '/MyEventsPage',
    '/CreateEventPage',
    '/EditEventPage'
  ]

  // Check if the current route is protected
  const isProtectedRoute = protectedRoutes.some(route => to.path.startsWith(route))

  if (isProtectedRoute) {
    // Check for authentication token
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    
    if (!token) {
      // User is not authorized (logged out)
      console.log('User not authorized - redirecting to login')
      
      // Store the intended destination
      localStorage.setItem('redirect_after_login', to.fullPath)
      
      // Redirect to login page
      return navigateTo('/LoginPage')
    }
  }
})
