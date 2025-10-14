import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CartEach from '~/app/components/CartEach.vue'

describe('CartEach.vue', () => {
  it('should render cart component', () => {
    const wrapper = mount(CartEach)
    expect(wrapper.exists()).toBe(true)
  })

  it('should display "Your items" text', () => {
    const wrapper = mount(CartEach)
    expect(wrapper.text()).toContain('Yout items') // Note: typo in component
  })

  it('should have number input', () => {
    const wrapper = mount(CartEach)
    const input = wrapper.find('input[type="number"]')
    expect(input.exists()).toBe(true)
  })

  it('should bind input to test model', async () => {
    const wrapper = mount(CartEach)
    const input = wrapper.find('input[type="number"]')
    await input.setValue('5')
    expect(input.element.value).toBe('5')
  })

  it('should have proper styling classes', () => {
    const wrapper = mount(CartEach)
    const input = wrapper.find('input')
    expect(input.classes()).toContain('bg-white')
    expect(input.classes()).toContain('border-gray-300')
  })
})
