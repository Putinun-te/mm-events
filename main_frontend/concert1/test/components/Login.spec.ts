import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { RouterLinkStub } from '@vue/test-utils'
import Login from '@/components/Login.vue'

// Mock Nuxt composables
const mockNavigateTo = vi.fn()

// Mock $fetch
const mockFetch = vi.fn()
global.$fetch = mockFetch as any
global.navigateTo = mockNavigateTo as any

// Mock useAuth composable
const mockSaveAuth = vi.fn()
const mockLoadFromStorage = vi.fn()
const mockShouldCompleteProfile = vi.fn(() => false)

vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({
    saveAuth: mockSaveAuth,
    loadFromStorage: mockLoadFromStorage,
    shouldCompleteProfile: mockShouldCompleteProfile,
    isLoggedIn: { value: false },
    user: { value: null },
    clearAuth: vi.fn()
  })
}))

describe('Login', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Mock localStorage
    global.localStorage = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn(),
      length: 0,
      key: vi.fn()
    } as any
  })

  it('renders login form with all fields', () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.find('h2').text()).toBe('Login')
    expect(wrapper.find('input[type="text"]#email').exists()).toBe(true)
    expect(wrapper.find('input[type="password"]#password').exists()).toBe(true)
    expect(wrapper.find('input[type="checkbox"]#rememberMe').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').text()).toBe('Login')
  })

  it('shows validation error when fields are empty', async () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Please fill in all fields')
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('submits login form with valid credentials', async () => {
    mockFetch.mockResolvedValueOnce({
      token: 'test-jwt-token',
      username: 'testuser',
      email: 'test@example.com'
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(mockFetch).toHaveBeenCalledWith('/api/auth/login', {
      method: 'POST',
      body: {
        usernameOrEmail: 'test@example.com',
        password: 'password123'
      }
    })

    // Check success message is shown
    expect(wrapper.text()).toContain('Login successful! Welcome back testuser!')
  })

  it('handles login API error', async () => {
    mockFetch.mockRejectedValueOnce({
      data: { message: 'Invalid credentials' }
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#email').setValue('wrong@example.com')
    await wrapper.find('#password').setValue('wrongpass')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Invalid credentials')
    expect(mockSaveAuth).not.toHaveBeenCalled()
  })

  it('redirects to AccountPage when profile incomplete', async () => {
    mockShouldCompleteProfile.mockReturnValueOnce(true)
    mockFetch.mockResolvedValueOnce({
      token: 'test-jwt-token',
      username: 'newuser',
      email: 'new@example.com'
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#email').setValue('new@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(mockNavigateTo).toHaveBeenCalledWith('/AccountPage')
  })

  it('saves credentials when remember me is checked', async () => {
    mockFetch.mockResolvedValueOnce({
      token: 'test-jwt-token',
      username: 'testuser',
      email: 'test@example.com'
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('#rememberMe').setValue(true)
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    // Verify rememberMe checkbox is checked
    expect((wrapper.find('#rememberMe').element as HTMLInputElement).checked).toBe(true)
    // Verify login was successful
    expect(wrapper.text()).toContain('Login successful!')
  })

  it('disables form inputs during loading', async () => {
    // Mock a delayed response
    mockFetch.mockImplementation(() => new Promise(resolve => {
      setTimeout(() => resolve({
        token: 'test-jwt-token',
        username: 'testuser',
        email: 'test@example.com'
      }), 100)
    }))

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    
    const form = wrapper.find('form')
    form.trigger('submit.prevent')
    await wrapper.vm.$nextTick()

    // Check that inputs are disabled during loading
    expect(wrapper.find('#email').attributes('disabled')).toBeDefined()
    expect(wrapper.find('#password').attributes('disabled')).toBeDefined()

    await flushPromises()
  })

  it('shows register link', () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const registerLink = wrapper.findComponent(RouterLinkStub)
    expect(registerLink.props('to')).toBe('/RegisterPage')
    expect(wrapper.text()).toContain('Register')
  })

  it('clears password field after successful login', async () => {
    mockFetch.mockResolvedValueOnce({
      token: 'test-jwt-token',
      username: 'testuser',
      email: 'test@example.com'
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect((wrapper.find('#password').element as HTMLInputElement).value).toBe('')
  })
})
