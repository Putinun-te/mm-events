import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import ProfilePage from '~/app/pages/ProfilePage.vue'

// Mock composables
const mockLoadFromStorage = vi.fn()
const mockIsLoggedIn = { value: true }

vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({
    loadFromStorage: mockLoadFromStorage,
    isLoggedIn: mockIsLoggedIn
  })
}))

// Mock $fetch
global.$fetch = vi.fn() as any

describe('ProfilePage.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    sessionStorage.clear()
    mockIsLoggedIn.value = true
  })

  // ==================== Success Cases ====================

  it('should render profile page with user data', async () => {
    // Arrange
    const mockUserData = {
      username: 'testuser',
      email: 'test@example.com'
    }
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('My Profile')
    expect(wrapper.text()).toContain('testuser')
    expect(wrapper.text()).toContain('test@example.com')
    expect(mockLoadFromStorage).toHaveBeenCalled()
  })

  it('should load profile data from localStorage', async () => {
    // Arrange
    const mockUserData = {
      username: 'testuser',
      email: 'test@example.com'
    }
    const mockProfile = {
      firstName: 'John',
      lastName: 'Doe',
      phone: '1234567890',
      address: '123 Main St',
      city: 'New York',
      country: 'USA',
      pincode: '10001'
    }
    localStorage.setItem('jwt_token', 'test-token')
    localStorage.setItem('profile_data', JSON.stringify(mockProfile))
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('John')
    expect(wrapper.text()).toContain('Doe')
    expect(wrapper.text()).toContain('1234567890')
    expect(wrapper.text()).toContain('123 Main St')
    expect(wrapper.text()).toContain('New York')
    expect(wrapper.text()).toContain('USA')
    expect(wrapper.text()).toContain('10001')
  })

  it('should display all profile fields when profile data exists', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    const mockProfile = {
      firstName: 'Alice',
      lastName: 'Smith',
      phone: '9876543210',
      address: '456 Oak Ave',
      city: 'Boston',
      country: 'USA',
      pincode: '02101'
    }
    localStorage.setItem('jwt_token', 'test-token')
    localStorage.setItem('profile_data', JSON.stringify(mockProfile))
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.html()).toContain('First Name')
    expect(wrapper.html()).toContain('Last Name')
    expect(wrapper.html()).toContain('Phone')
    expect(wrapper.html()).toContain('Address')
    expect(wrapper.html()).toContain('City')
    expect(wrapper.html()).toContain('Country')
    expect(wrapper.html()).toContain('Pincode')
  })

  it('should show "No personal info yet" when profile is null', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'test-token')
    // No profile_data in localStorage
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('No personal info yet')
  })

  it('should use token from localStorage', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'local-storage-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(global.$fetch).toHaveBeenCalledWith('/api/auth/me', {
      headers: { Authorization: 'Bearer local-storage-token' }
    })
  })

  it('should fallback to sessionStorage token if localStorage is empty', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    sessionStorage.setItem('jwt_token', 'session-storage-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(global.$fetch).toHaveBeenCalledWith('/api/auth/me', {
      headers: { Authorization: 'Bearer session-storage-token' }
    })
  })

  it('should use empty string if no token is found', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(global.$fetch).toHaveBeenCalledWith('/api/auth/me', {
      headers: { Authorization: 'Bearer ' }
    })
  })

  it('should display "-" for missing username', async () => {
    // Arrange
    const mockUserData = { email: 'test@example.com' } // No username
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Username')
    expect(wrapper.text()).toContain('-')
  })

  it('should display "-" for missing email', async () => {
    // Arrange
    const mockUserData = { username: 'testuser' } // No email
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Email')
    expect(wrapper.text()).toContain('-')
  })

  it('should display "-" for missing profile fields', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    const mockProfile = { firstName: 'John' } // Only firstName, others missing
    localStorage.setItem('jwt_token', 'test-token')
    localStorage.setItem('profile_data', JSON.stringify(mockProfile))
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('John') // firstName present
    expect(wrapper.text()).toContain('-') // Other fields have "-"
  })

  // ==================== Error Cases ====================

  it('should show error message when not logged in', async () => {
    // Arrange
    mockIsLoggedIn.value = false

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Please login to view your profile')
    expect(global.$fetch).not.toHaveBeenCalled()
  })

  it('should handle API error with message', async () => {
    // Arrange
    localStorage.setItem('jwt_token', 'test-token')
    const errorMessage = 'Unauthorized access'
    ;(global.$fetch as any).mockRejectedValue({
      data: { message: errorMessage }
    })

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain(errorMessage)
    expect(wrapper.find('.bg-red-500').exists()).toBe(true)
  })

  it('should handle API error without specific message', async () => {
    // Arrange
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockRejectedValue(new Error('Network error'))

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Failed to load profile')
    expect(wrapper.find('.bg-red-500').exists()).toBe(true)
  })

  it('should handle API error with data but no message', async () => {
    // Arrange
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockRejectedValue({ data: {} })

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Failed to load profile')
  })

  it('should log error to console when API fails', async () => {
    // Arrange
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    localStorage.setItem('jwt_token', 'test-token')
    const error = new Error('API Error')
    ;(global.$fetch as any).mockRejectedValue(error)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(consoleErrorSpy).toHaveBeenCalledWith('Load profile error', error)
    consoleErrorSpy.mockRestore()
  })

  // ==================== Loading States ====================

  it('should show loading state initially', () => {
    // Arrange
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockImplementation(() => new Promise(() => {})) // Never resolves

    // Act
    const wrapper = mount(ProfilePage)

    // Assert
    expect(wrapper.text()).toContain('Loading...')
  })

  it('should hide loading state after data loads', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).not.toContain('Loading...')
  })

  it('should hide loading state after error', async () => {
    // Arrange
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockRejectedValue(new Error('API Error'))

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).not.toContain('Loading...')
  })

  it('should hide loading state when not logged in', async () => {
    // Arrange
    mockIsLoggedIn.value = false

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).not.toContain('Loading...')
  })

  // ==================== UI Elements ====================

  it('should have "Edit Profile" link', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Edit Profile')
  })

  it('should display account section', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Account')
    expect(wrapper.text()).toContain('Username')
    expect(wrapper.text()).toContain('Email')
  })

  it('should display personal info section', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'test-token')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Personal Info')
  })

  // ==================== Profile Data Parsing ====================

  it('should parse profile data from localStorage correctly', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    const mockProfile = {
      firstName: 'Test',
      lastName: 'User',
      phone: '555-1234',
      address: '789 Test Rd',
      city: 'Test City',
      country: 'Test Country',
      pincode: '12345'
    }
    localStorage.setItem('jwt_token', 'test-token')
    localStorage.setItem('profile_data', JSON.stringify(mockProfile))
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act
    const wrapper = mount(ProfilePage)
    await flushPromises()

    // Assert
    expect(wrapper.text()).toContain('Test')
    expect(wrapper.text()).toContain('User')
    expect(wrapper.text()).toContain('555-1234')
    expect(wrapper.text()).toContain('789 Test Rd')
    expect(wrapper.text()).toContain('Test City')
    expect(wrapper.text()).toContain('Test Country')
    expect(wrapper.text()).toContain('12345')
  })

  it('should handle malformed JSON in profile_data gracefully', async () => {
    // Arrange
    const mockUserData = { username: 'testuser', email: 'test@example.com' }
    localStorage.setItem('jwt_token', 'test-token')
    localStorage.setItem('profile_data', 'invalid-json{')
    ;(global.$fetch as any).mockResolvedValue(mockUserData)

    // Act & Assert - Should handle JSON.parse error gracefully
    const wrapper = mount(ProfilePage)
    await flushPromises()
    
    // Component should still render with basic user data
    expect(wrapper.text()).toContain('testuser')
    expect(wrapper.text()).toContain('test@example.com')
  })
})
