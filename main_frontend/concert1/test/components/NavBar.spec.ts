import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBar from '@/components/NavBar.vue'
import { RouterLinkStub } from '@vue/test-utils'

// Mock useAuth
vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({
    isLoggedIn: { value: false },
    user: { value: null },
    clearAuth: vi.fn()
  })
}))

describe('NavBar', () => {
  it('renders NavBar component', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('shows MM Concerts brand name', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })
    expect(wrapper.text()).toContain('MM Concerts')
  })

  it('shows navigation items', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })
    expect(wrapper.text()).toContain('Home')
    expect(wrapper.text()).toContain('Events')
    expect(wrapper.text()).toContain('About')
  })

  it('shows navigation buttons', () => {
    const wrapper = mount(NavBar, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })
    // Component shows either Sign In or User menu depending on auth state
    const text = wrapper.text()
    const hasSignIn = text.includes('Sign In') || text.includes('Get Started')
    const hasUserMenu = text.includes('User') || text.includes('Create Event')
    expect(hasSignIn || hasUserMenu).toBe(true)
  })
})
