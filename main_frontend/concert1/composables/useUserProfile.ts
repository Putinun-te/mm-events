// User profile composable for state management
import { ref, computed } from 'vue'

interface UserProfile {
  id: string
  email: string
  fullName: string
  avatar: string
  bio: string
  phone: string
  location: string
  website: string
  role: 'user' | 'organizer' | 'admin'
  status: 'active' | 'suspended' | 'inactive'
  createdAt: Date
  updatedAt: Date
}

interface UserStats {
  bookings: number
  eventsAttended: number
  eventsCreated: number
  followers: number
  following: number
  reviews: number
  averageRating: number
}

// Global user state
const currentUser = ref<UserProfile | null>(null)
const userStats = ref<UserStats>({
  bookings: 0,
  eventsAttended: 0,
  eventsCreated: 0,
  followers: 0,
  following: 0,
  reviews: 0,
  averageRating: 0
})

const isAuthenticated = computed(() => !!currentUser.value)
const isLoading = ref(false)
const error = ref<string | null>(null)

/**
 * Initialize user profile
 */
export const useUserProfile = () => {
  /**
   * Fetch current user profile
   */
  const fetchUserProfile = async () => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/auth/me', {
        method: 'GET'
      })

      currentUser.value = response.user
      userStats.value = response.stats
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch user profile'
      console.error('Error fetching user profile:', err)
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Update user profile
   */
  const updateProfile = async (updates: Partial<UserProfile>) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/profile', {
        method: 'PUT',
        body: updates
      })

      currentUser.value = response.user
      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to update profile'
      console.error('Error updating profile:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Update user avatar
   */
  const updateAvatar = async (file: File) => {
    try {
      isLoading.value = true
      error.value = null

      const formData = new FormData()
      formData.append('avatar', file)

      const response = await $fetch('/api/user/avatar', {
        method: 'POST',
        body: formData
      })

      if (currentUser.value) {
        currentUser.value.avatar = response.url
      }

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to update avatar'
      console.error('Error updating avatar:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Change password
   */
  const changePassword = async (currentPassword: string, newPassword: string) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/password', {
        method: 'POST',
        body: {
          currentPassword,
          newPassword
        }
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to change password'
      console.error('Error changing password:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Update notification preferences
   */
  const updateNotificationSettings = async (settings: Record<string, any>) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/notifications', {
        method: 'PUT',
        body: settings
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to update notification settings'
      console.error('Error updating notification settings:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Update privacy settings
   */
  const updatePrivacySettings = async (settings: Record<string, any>) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/privacy', {
        method: 'PUT',
        body: settings
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to update privacy settings'
      console.error('Error updating privacy settings:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Enable two-factor authentication
   */
  const enableTwoFactor = async () => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/two-factor/enable', {
        method: 'POST'
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to enable two-factor authentication'
      console.error('Error enabling two-factor authentication:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Disable two-factor authentication
   */
  const disableTwoFactor = async (code: string) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/two-factor/disable', {
        method: 'POST',
        body: { code }
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to disable two-factor authentication'
      console.error('Error disabling two-factor authentication:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Logout from device session
   */
  const logoutFromDevice = async (sessionId: string) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch(`/api/user/sessions/${sessionId}`, {
        method: 'DELETE'
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to logout from device'
      console.error('Error logging out from device:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Block user
   */
  const blockUser = async (userId: string) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/blocked-users', {
        method: 'POST',
        body: { userId }
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to block user'
      console.error('Error blocking user:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Unblock user
   */
  const unblockUser = async (userId: string) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch(`/api/user/blocked-users/${userId}`, {
        method: 'DELETE'
      })

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to unblock user'
      console.error('Error unblocking user:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Delete account
   */
  const deleteAccount = async (password: string) => {
    try {
      isLoading.value = true
      error.value = null

      const response = await $fetch('/api/user/account', {
        method: 'DELETE',
        body: { password }
      })

      currentUser.value = null

      return response
    } catch (err: any) {
      error.value = err.message || 'Failed to delete account'
      console.error('Error deleting account:', err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Logout user
   */
  const logout = () => {
    currentUser.value = null
    error.value = null
  }

  return {
    // State
    currentUser,
    userStats,
    isAuthenticated,
    isLoading,
    error,

    // Methods
    fetchUserProfile,
    updateProfile,
    updateAvatar,
    changePassword,
    updateNotificationSettings,
    updatePrivacySettings,
    enableTwoFactor,
    disableTwoFactor,
    logoutFromDevice,
    blockUser,
    unblockUser,
    deleteAccount,
    logout
  }
}
