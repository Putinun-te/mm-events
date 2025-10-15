import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ProductTag from '~/app/components/ProductTag.vue'

describe('ProductTag.vue', () => {
  it('should render tag', () => {
    const wrapper = mount(ProductTag, {
      props: { label: 'Music' }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should display tag label', () => {
    const wrapper = mount(ProductTag, {
      props: { label: 'Music' }
    })
    expect(wrapper.html()).toContain('Music')
  })

  it('should apply color variant', () => {
    const wrapper = mount(ProductTag, {
      props: { label: 'Sports', color: 'blue' }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should be clickable', async () => {
    const wrapper = mount(ProductTag, {
      props: { label: 'Tech', clickable: true }
    })
    wrapper.vm.$emit('click')
    expect(wrapper.emitted()).toHaveProperty('click')
  })
})
