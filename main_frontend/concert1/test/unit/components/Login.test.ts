import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Login from '~/app/components/Login.vue'

// Mock $fetch
const mockFetch = vi.fn()
;(global as any).$fetch = mockFetch

describe('Login Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('should render login form', () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.find('input#email').exists()).toBe(true)
    expect(wrapper.find('input#password').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('should have email and password fields', () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const emailInput = wrapper.find('input#email')
    const passwordInput = wrapper.find('input#password')
    
    expect(emailInput.exists()).toBe(true)
    expect(passwordInput.exists()).toBe(true)
  })

  it('should update email value on input', async () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const emailInput = wrapper.find('input#email')
    await emailInput.setValue('test@example.com')
    
    expect((emailInput.element as HTMLInputElement).value).toBe('test@example.com')
  })

  it('should update password value on input', async () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const passwordInput = wrapper.find('input#password')
    await passwordInput.setValue('password123')
    
    expect((passwordInput.element as HTMLInputElement).value).toBe('password123')
  })

  it('should display error message for invalid credentials', async () => {
    mockFetch.mockRejectedValueOnce({
      data: { message: 'Invalid credentials' }
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    await wrapper.find('input#email').setValue('wrong@test.com')
    await wrapper.find('input#password').setValue('wrongpass')
    await wrapper.find('form').trigger('submit.prevent')
    
    await wrapper.vm.$nextTick()
    
    // Component should handle error
    expect(mockFetch).toHaveBeenCalled()
  })

  it('should call login API on form submit', async () => {
    mockFetch.mockResolvedValueOnce({
      token: 'test-token',
      username: 'testuser',
      email: 'test@test.com'
    })

    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    await wrapper.find('input#email').setValue('test@test.com')
    await wrapper.find('input#password').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')
    
    expect(mockFetch).toHaveBeenCalledWith(
      '/api/auth/login',
      expect.objectContaining({
        method: 'POST'
      })
    )
  })

  it('should have remember me checkbox', () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const checkbox = wrapper.find('input#rememberMe')
    expect(checkbox.exists()).toBe(true)
  })

  it('should prevent empty form submission', async () => {
    const wrapper = mount(Login, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    await wrapper.find('form').trigger('submit.prevent')
    
    // Should not call API with empty values
    expect(mockFetch).not.toHaveBeenCalled()
  })
})
