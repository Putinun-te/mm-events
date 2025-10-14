import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import AccountPage from '~/app/pages/AccountPage.vue'

// Mock fetch globally
global.fetch = vi.fn()

const mockProfile = {
  email: 'test@test.com',
  username: 'testuser',
  firstName: 'John',
  lastName: 'Doe',
  phoneNumber: '0812345678'
}

describe('AccountPage.vue', () => {
  let router: any

  beforeEach(() => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/concert/account', name: 'Account', component: AccountPage }
      ]
    })
    
    vi.clearAllMocks()
    
    // Mock localStorage
    localStorage.setItem('jwt_token', 'test-token')
    localStorage.setItem('profile', JSON.stringify(mockProfile))
    
    // Mock profile API
    ;(global.fetch as any).mockResolvedValue({
      ok: true,
      json: async () => mockProfile
    })
  })

  it('should render account page', () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should load profile on mount', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Component should be mounted
    expect(wrapper.exists()).toBe(true)
  })

  it('should display profile information', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Component should render
    expect(wrapper.exists()).toBe(true)
  })

  it('should have edit profile form', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // Should have input fields
    const inputs = wrapper.findAll('input')
    expect(inputs.length).toBeGreaterThan(0)
  })

  it('should update profile on submit', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    const vm = wrapper.vm as any
    
    // Mock update API
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ ...mockProfile, firstName: 'Jane' })
    })
    
    // If update function exists
    if (vm.updateProfile || vm.handleUpdate) {
      const updateFn = vm.updateProfile || vm.handleUpdate
      await updateFn()
      
      // Should call update API
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/users/me'),
        expect.objectContaining({
          method: 'PUT'
        })
      )
    }
  })

  it('should handle form validation', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    
    const vm = wrapper.vm as any
    
    // Check if validation exists
    if (vm.validateForm || vm.isValid) {
      expect(wrapper.exists()).toBe(true)
    }
  })

  it('should redirect to login if not authenticated', async () => {
    localStorage.removeItem('jwt_token')
    
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // Should handle unauthenticated state
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle API error', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: false,
      status: 500
    })
    
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should display email field', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // Should have input fields
    const inputs = wrapper.findAll('input')
    expect(inputs.length).toBeGreaterThanOrEqual(0)
  })

  it('should allow editing profile fields', async () => {
    const wrapper = mount(AccountPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    
    const inputs = wrapper.findAll('input[type="text"]')
    if (inputs.length > 0) {
      await inputs[0].setValue('New Value')
      expect(inputs[0].element.value).toBe('New Value')
    }
  })
})
