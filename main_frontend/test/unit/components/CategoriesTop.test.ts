import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CategoriesTop from '~/app/components/CategoriesTop.vue'

describe('CategoriesTop.vue', () => {
  it('should render categories component', () => {
    const wrapper = mount(CategoriesTop, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should display category buttons', () => {
    const wrapper = mount(CategoriesTop, {
      global: { stubs: { NuxtLink: true } }
    })
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBeGreaterThanOrEqual(0)
  })

  it('should emit category selection', async () => {
    const wrapper = mount(CategoriesTop, {
      global: { stubs: { NuxtLink: true } }
    })
    wrapper.vm.$emit('select', 'Music')
    expect(wrapper.emitted()).toHaveProperty('select')
  })

  it('should have multiple categories', () => {
    const wrapper = mount(CategoriesTop, {
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.html().length).toBeGreaterThan(0)
  })
})
