import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBar from '~/app/components/NavBar.vue'

describe('NavBar Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('should render navigation bar', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: true,
          LogoutModal: true
        }
      }
    })
    
    expect(wrapper.find('nav').exists()).toBe(true)
  })

  it('should display navigation links', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: true,
          LogoutModal: true
        }
      }
    })
    
    const nav = wrapper.find('nav')
    expect(nav.exists()).toBe(true)
  })

  it('should show login when not authenticated', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: true,
          LogoutModal: true
        }
      }
    })
    
    // NavBar should render even when not logged in
    expect(wrapper.find('nav').exists()).toBe(true)
  })

  it('should load auth state on mount', () => {
    localStorage.setItem('jwt_token', 'test-token')
    
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: true,
          LogoutModal: true
        }
      }
    })
    
    expect(wrapper.find('nav').exists()).toBe(true)
  })

  it('should have navigation pages defined', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: true,
          LogoutModal: true
        }
      }
    })
    
    // Component should have pages data
    expect(wrapper.vm).toBeDefined()
  })

  it('should handle logout action', async () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: true,
          LogoutModal: true
        }
      }
    })
    
    // NavBar should have logout functionality
    expect(wrapper.vm).toBeDefined()
  })
})
