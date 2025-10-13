import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { RouterLinkStub } from '@vue/test-utils'
import Register from '@/components/Register.vue'

// Mock Nuxt composables
const mockNavigateTo = vi.fn()

// Mock $fetch
const mockFetch = vi.fn()
global.$fetch = mockFetch as any
global.navigateTo = mockNavigateTo as any

describe('Register', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders registration form with all fields', () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.find('h2').text()).toBe('Create Your Account')
    expect(wrapper.find('#username').exists()).toBe(true)
    expect(wrapper.find('#email').exists()).toBe(true)
    expect(wrapper.find('#password').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').text()).toBe('Register')
  })

  it('validates required fields', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Please fill all fields')
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('validates email format', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('testuser')
    await wrapper.find('#email').setValue('invalid-email')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Please enter a valid email')
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('validates password length (minimum 6 characters)', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('testuser')
    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('12345')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Password must be at least 6 characters')
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('submits registration with valid data', async () => {
    mockFetch.mockResolvedValueOnce({
      token: 'test-jwt-token',
      username: 'testuser',
      email: 'test@example.com'
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('testuser')
    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(mockFetch).toHaveBeenCalledWith('/api/auth/register', {
      method: 'POST',
      body: {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      }
    })

    expect(wrapper.text()).toContain('Registered successfully! Please login.')
    expect(mockNavigateTo).toHaveBeenCalledWith('/LoginPage')
  })

  it('handles registration API error', async () => {
    mockFetch.mockRejectedValueOnce({
      data: { message: 'Username already exists' }
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('existinguser')
    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Username already exists')
    expect(mockNavigateTo).not.toHaveBeenCalled()
  })

  it('handles email already exists error', async () => {
    mockFetch.mockRejectedValueOnce({
      data: { message: 'Email already registered' }
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('testuser')
    await wrapper.find('#email').setValue('existing@example.com')
    await wrapper.find('#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Email already registered')
  })

  it('disables form during submission', async () => {
    mockFetch.mockImplementation(() => new Promise(resolve => {
      setTimeout(() => resolve({
        token: 'test-jwt-token',
        username: 'testuser',
        email: 'test@example.com'
      }), 100)
    }))

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('testuser')
    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    
    wrapper.find('form').trigger('submit.prevent')
    await wrapper.vm.$nextTick()

    // Inputs should be disabled during loading
    expect(wrapper.find('#username').attributes('disabled')).toBeDefined()
    expect(wrapper.find('#email').attributes('disabled')).toBeDefined()
    expect(wrapper.find('#password').attributes('disabled')).toBeDefined()

    await flushPromises()
  })

  it('shows login link for existing users', () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const loginLink = wrapper.findComponent(RouterLinkStub)
    expect(loginLink.props('to')).toBe('/LoginPage')
    expect(wrapper.text()).toContain('Log in')
  })

  it('accepts valid email formats', async () => {
    const validEmails = [
      'test@example.com',
      'user.name@example.co.uk',
      'user+tag@example.com',
      'user123@test-domain.org'
    ]

    for (const email of validEmails) {
      mockFetch.mockResolvedValueOnce({
        token: 'test-jwt-token',
        username: 'testuser',
        email: email
      })

      const wrapper = mount(Register, {
        global: {
          stubs: {
            NuxtLink: RouterLinkStub
          }
        }
      })

      await wrapper.find('#username').setValue('testuser')
      await wrapper.find('#email').setValue(email)
      await wrapper.find('#password').setValue('password123')
      await wrapper.find('form').trigger('submit.prevent')
      await flushPromises()

      expect(mockFetch).toHaveBeenCalled()
    }
  })

  it('prevents double submission', async () => {
    mockFetch.mockImplementation(() => new Promise(resolve => {
      setTimeout(() => resolve({
        token: 'test-jwt-token',
        username: 'testuser',
        email: 'test@example.com'
      }), 100)
    }))

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('#username').setValue('testuser')
    await wrapper.find('#email').setValue('test@example.com')
    await wrapper.find('#password').setValue('password123')
    
    // Try to submit twice quickly
    wrapper.find('form').trigger('submit.prevent')
    wrapper.find('form').trigger('submit.prevent')
    
    await flushPromises()

    // Should only call API once
    expect(mockFetch).toHaveBeenCalledTimes(1)
  })
})
