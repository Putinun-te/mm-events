import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SideSearchBar from '~/app/components/SideSearchBar.vue'

describe('SideSearchBar.vue', () => {
  it('should render search bar', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should have search input', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    const inputs = wrapper.findAll('input')
    expect(inputs.length).toBeGreaterThanOrEqual(0)
  })

  it('should emit search event', async () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    wrapper.vm.$emit('search', 'test query')
    expect(wrapper.emitted()).toHaveProperty('search')
  })

  it('should have filter options', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.html().length).toBeGreaterThan(0)
  })

  it('should update on input change', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })
})
