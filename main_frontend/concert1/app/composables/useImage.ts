export const useImage = () => {
  const PLACEHOLDER_IMAGE = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><rect width="256" height="256" rx="24" fill="%23e2e8f0"/><text x="50%25" y="52%25" dominant-baseline="middle" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-size="36" fill="%234a5568">Event</text></svg>'
  
  const AVATAR_PLACEHOLDER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><rect width="256" height="256" rx="128" fill="%23e2e8f0"/><circle cx="128" cy="100" r="40" fill="%234a5568"/><path d="M 128 150 Q 80 150 60 200 L 196 200 Q 176 150 128 150" fill="%234a5568"/></svg>'

  const S3_BASE_URL = 'https://concert-event-pictures-singapore-123456789012.s3.ap-southeast-1.amazonaws.com'

  /**
   * Get event photo URL with fallback to placeholder
   */
  const getEventPhotoUrl = (photoUrl: string | null | undefined): string => {
    if (!photoUrl || photoUrl === 'null' || photoUrl.trim() === '') {
      return PLACEHOLDER_IMAGE
    }
    
    // If already full URL, return as is
    if (photoUrl.startsWith('http')) {
      return photoUrl
    }
    
    // If relative path, prepend S3 base URL
    return `${S3_BASE_URL}/${photoUrl.replace(/^\//, '')}`
  }

  /**
   * Get avatar URL with fallback to placeholder
   */
  const getAvatarUrl = (avatarUrl: string | null | undefined): string => {
    if (!avatarUrl || avatarUrl === 'null' || avatarUrl.trim() === '') {
      return AVATAR_PLACEHOLDER
    }
    
    if (avatarUrl.startsWith('http')) {
      return avatarUrl
    }
    
    return `${S3_BASE_URL}/${avatarUrl.replace(/^\//, '')}`
  }

  /**
   * Check if image URL is valid and accessible
   */
  const isImageValid = async (url: string): Promise<boolean> => {
    try {
      const response = await fetch(url, { method: 'HEAD' })
      return response.ok
    } catch {
      return false
    }
  }

  /**
   * Get image URL with validation and fallback
   */
  const getValidatedImageUrl = async (
    url: string | null | undefined,
    type: 'event' | 'avatar' = 'event'
  ): Promise<string> => {
    const imageUrl = type === 'event' ? getEventPhotoUrl(url) : getAvatarUrl(url)
    
    // If it's a placeholder, return immediately
    if (imageUrl.startsWith('data:')) {
      return imageUrl
    }
    
    // Validate the URL
    const isValid = await isImageValid(imageUrl)
    return isValid ? imageUrl : (type === 'event' ? PLACEHOLDER_IMAGE : AVATAR_PLACEHOLDER)
  }

  return {
    getEventPhotoUrl,
    getAvatarUrl,
    isImageValid,
    getValidatedImageUrl,
    PLACEHOLDER_IMAGE,
    AVATAR_PLACEHOLDER,
    S3_BASE_URL
  }
}
