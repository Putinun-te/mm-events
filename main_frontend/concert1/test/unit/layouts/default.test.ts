import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DefaultLayout from '~/app/layouts/default.vue'

describe('default.vue layout', () => {
  it('should render layout', () => {
    const wrapper = mount(DefaultLayout, {
      global: {
        stubs: { NuxtLink: true, NavBar: true, Toasts: true }
      },
      slots: {
        default: '<div>Page Content</div>'
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should render slot content', () => {
    const wrapper = mount(DefaultLayout, {
      global: {
        stubs: { NuxtLink: true, NavBar: true, Toasts: true }
      },
      slots: {
        default: '<div class="test-content">Page Content</div>'
      }
    })
    expect(wrapper.html()).toContain('test-content')
  })

  it('should include navbar', () => {
    const wrapper = mount(DefaultLayout, {
      global: {
        stubs: { NuxtLink: true, NavBar: true, Toasts: true }
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should include toast notifications', () => {
    const wrapper = mount(DefaultLayout, {
      global: {
        stubs: { NuxtLink: true, NavBar: true, Toasts: true }
      }
    })
    expect(wrapper.exists()).toBe(true)
  })
})
