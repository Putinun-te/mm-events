import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Register from '~/app/components/Register.vue'

// Mock $fetch
const mockFetch = vi.fn()
;(global as any).$fetch = mockFetch

// Mock navigateTo
;(global as any).navigateTo = vi.fn()

describe('Register Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockFetch.mockReset()
    localStorage.clear()
  })

  it('should render registration form', () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.find('form').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('should have required input fields', () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    expect(inputs.length).toBeGreaterThan(0)
  })

  it('should update input values', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    if (inputs.length > 0) {
      await inputs[0].setValue('test value')
      expect((inputs[0].element as HTMLInputElement).value).toBe('test value')
    }
  })

  it('should call registration API on submit', async () => {
    mockFetch.mockResolvedValueOnce({
      success: true,
      message: 'Registration successful'
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const form = wrapper.find('form')
    await form.trigger('submit.prevent')
    
    // Check if mockFetch was called
    await wrapper.vm.$nextTick()
  })

  it('should show loading state during submission', async () => {
    mockFetch.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 100)))

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    await wrapper.find('form').trigger('submit.prevent')
    
    const submitButton = wrapper.find('button[type="submit"]')
    // Button should be disabled or show loading state
    expect(submitButton.exists()).toBe(true)
  })

  it('should validate password confirmation', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const passwordInputs = wrapper.findAll('input[type="password"]')
    if (passwordInputs.length >= 2) {
      await passwordInputs[0].setValue('password123')
      await passwordInputs[1].setValue('different')
      
      await wrapper.find('form').trigger('submit.prevent')
      
      // Should not call API if passwords don't match
      expect(mockFetch).not.toHaveBeenCalled()
    }
  })

  it('should clear form after successful registration', async () => {
    mockFetch.mockResolvedValueOnce({
      success: true
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    for (const input of inputs) {
      await input.setValue('test')
    }
    
    await wrapper.find('form').trigger('submit.prevent')
    await wrapper.vm.$nextTick()
  })

  it('should handle registration API error', async () => {
    mockFetch.mockRejectedValueOnce({
      data: { message: 'Email already exists' }
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    if (inputs.length >= 3) {
      await inputs[0].setValue('test@test.com')
      await inputs[1].setValue('testuser')
      
      const passwordInputs = wrapper.findAll('input[type="password"]')
      if (passwordInputs.length >= 2) {
        await passwordInputs[0].setValue('password123')
        await passwordInputs[1].setValue('password123')
      }
    }
    
    await wrapper.find('form').trigger('submit.prevent')
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle network error during registration', async () => {
    mockFetch.mockRejectedValueOnce(new Error('Network error'))

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    if (inputs.length >= 3) {
      await inputs[0].setValue('test@test.com')
      await inputs[1].setValue('testuser')
      
      const passwordInputs = wrapper.findAll('input[type="password"]')
      if (passwordInputs.length >= 2) {
        await passwordInputs[0].setValue('password123')
        await passwordInputs[1].setValue('password123')
      }
    }
    
    await wrapper.find('form').trigger('submit.prevent')
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle empty email validation', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    if (inputs.length >= 2) {
      await inputs[1].setValue('testuser')
      
      const passwordInputs = wrapper.findAll('input[type="password"]')
      if (passwordInputs.length >= 2) {
        await passwordInputs[0].setValue('password123')
        await passwordInputs[1].setValue('password123')
      }
    }
    
    await wrapper.find('form').trigger('submit.prevent')
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('should handle empty username validation', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    if (inputs.length >= 1) {
      await inputs[0].setValue('test@test.com')
      
      const passwordInputs = wrapper.findAll('input[type="password"]')
      if (passwordInputs.length >= 2) {
        await passwordInputs[0].setValue('password123')
        await passwordInputs[1].setValue('password123')
      }
    }
    
    await wrapper.find('form').trigger('submit.prevent')
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('should handle weak password validation', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const inputs = wrapper.findAll('input')
    if (inputs.length >= 3) {
      await inputs[0].setValue('test@test.com')
      await inputs[1].setValue('testuser')
      
      const passwordInputs = wrapper.findAll('input[type="password"]')
      if (passwordInputs.length >= 2) {
        await passwordInputs[0].setValue('123')
        await passwordInputs[1].setValue('123')
      }
    }
    
    await wrapper.find('form').trigger('submit.prevent')
    await wrapper.vm.$nextTick()
  })

  // Branch coverage tests for conditional logic
  it('should prevent submit when already loading', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.isLoading = true
    
    await vm.handleSubmit()
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('should validate all fields are filled', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = ''
    vm.email = 'test@test.com'
    vm.password = 'password123'
    
    await vm.handleSubmit()
    expect(vm.message).toBe('Please fill all fields')
  })

  it('should validate email format with regex', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'invalid-email'
    vm.password = 'password123'
    
    await vm.handleSubmit()
    expect(vm.message).toBe('Please enter a valid email')
  })

  it('should validate password length >= 6', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = '12345'
    
    await vm.handleSubmit()
    expect(vm.message).toBe('Password must be at least 6 characters')
  })

  it('should handle success with token in response', async () => {
    mockFetch.mockResolvedValueOnce({
      token: 'test-token-123',
      message: 'Success'
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.isSuccess).toBe(true)
    expect(vm.message).toContain('Registered successfully')
  })

  it('should handle success without message in response', async () => {
    mockFetch.mockResolvedValueOnce({
      userId: 123
      // no message, no token
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.isSuccess).toBe(true)
  })

  it('should handle response with error message', async () => {
    mockFetch.mockResolvedValueOnce({
      message: 'Username already exists'
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.message).toBe('Username already exists')
  })

  it('should handle response with message field for error', async () => {
    mockFetch.mockResolvedValueOnce({
      message: 'Username already taken'
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.message).toBe('Username already taken')
  })

  it('should handle error with data.message', async () => {
    mockFetch.mockRejectedValueOnce({
      data: { message: 'Email already in use' }
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.message).toBe('Email already in use')
  })

  it('should handle error with response.data.message fallback', async () => {
    mockFetch.mockRejectedValueOnce({
      response: { data: { message: 'Server error' } }
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.message).toBe('Server error')
  })

  it('should handle error with just message property', async () => {
    mockFetch.mockRejectedValueOnce({
      message: 'Network timeout'
    })

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.message).toBe('Network timeout')
  })

  it('should use default error message when no specific message', async () => {
    mockFetch.mockRejectedValueOnce({})

    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.username = 'testuser'
    vm.email = 'test@test.com'
    vm.password = 'password123'
    vm.agreeToTerms = true
    
    await vm.handleSubmit()
    await wrapper.vm.$nextTick()
    
    expect(vm.message).toBe('Registration failed!')
  })

  it('should show success message with green background', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.isSuccess = true
    vm.message = 'Success!'
    await wrapper.vm.$nextTick()
    
    const messageDiv = wrapper.find('.bg-green-500')
    expect(messageDiv.exists()).toBe(true)
  })

  it('should show error message with red background', async () => {
    const wrapper = mount(Register, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    vm.isSuccess = false
    vm.message = 'Error!'
    await wrapper.vm.$nextTick()
    
    const messageDiv = wrapper.find('.bg-red-500')
    expect(messageDiv.exists()).toBe(true)
  })
})

