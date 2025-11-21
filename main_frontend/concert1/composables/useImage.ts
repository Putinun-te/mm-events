/**
 * Composable for handling image URLs and transformations
 */
export const useImage = () => {
  // Get backend URL from environment or use default
  const getBackendUrl = () => {
    if (process.client && typeof window !== 'undefined') {
      return window.location.origin.includes('localhost')
        ? 'http://localhost:8080'
        : (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080')
    }
    return 'http://localhost:8080'
  }
  
  /**
   * Get the full URL for an event photo
   * @param photoUrl - The photo URL from the API (could be relative or absolute)
   * @returns Full URL for the photo
   */
  const getEventPhotoUrl = (photoUrl: string | null | undefined): string => {
    if (!photoUrl) {
      // Return a placeholder image
      return '/img/event-placeholder.jpg'
    }

    // If it's already a full URL (starts with http:// or https://), return as-is
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl
    }

    // If it's a relative URL, prepend the backend API base URL
    const backendUrl = getBackendUrl()
    return `${backendUrl}${photoUrl.startsWith('/') ? '' : '/'}${photoUrl}`
  }

  /**
   * Get the full URL for a user avatar
   * @param avatarUrl - The avatar URL from the API
   * @returns Full URL for the avatar
   */
  const getUserAvatarUrl = (avatarUrl: string | null | undefined): string => {
    if (!avatarUrl) {
      return '/img/default-avatar.png'
    }

    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return avatarUrl
    }

    const backendUrl = getBackendUrl()
    return `${backendUrl}${avatarUrl.startsWith('/') ? '' : '/'}${avatarUrl}`
  }

  /**
   * Create a thumbnail URL with size parameters
   * @param imageUrl - The original image URL
   * @param width - Desired width
   * @param height - Desired height
   * @returns URL with size parameters
   */
  const getThumbnailUrl = (imageUrl: string, width?: number, height?: number): string => {
    const fullUrl = getEventPhotoUrl(imageUrl)
    
    if (!width && !height) {
      return fullUrl
    }

    const params = new URLSearchParams()
    if (width) params.set('w', width.toString())
    if (height) params.set('h', height.toString())
    
    return `${fullUrl}?${params.toString()}`
  }

  return {
    getEventPhotoUrl,
    getUserAvatarUrl,
    getThumbnailUrl
  }
}
