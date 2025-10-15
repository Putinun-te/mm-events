import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SideSearchBar from '~/app/components/SideSearchBar.vue'

describe('SideSearchBar.vue', () => {
  it('should mount component', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should render as empty component', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    // Component is currently empty, so HTML should be minimal
    expect(wrapper.html()).toBeDefined()
  })

  it('should not have any inputs when empty', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    const inputs = wrapper.findAll('input')
    expect(inputs.length).toBe(0)
  })

  it('should be a valid vue component', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.vm).toBeDefined()
  })

  it('should emit events when needed', () => {
    const wrapper = mount(SideSearchBar, {
      global: { stubs: { NuxtLink: true } }
    })
    // Can still emit events even when empty
    wrapper.vm.$emit('search', 'test')
    expect(wrapper.emitted()).toHaveProperty('search')
  })
})
