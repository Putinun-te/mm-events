import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CartEach from '~/app/components/CartEach.vue'

describe('CartEach.vue', () => {
  const mockItem = {
    id: 1,
    title: 'Test Event',
    quantity: 2,
    price: 100
  }

  it('should render cart item', () => {
    const wrapper = mount(CartEach, {
      props: { item: mockItem },
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should display item title', () => {
    const wrapper = mount(CartEach, {
      props: { item: mockItem },
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.html()).toContain('Test Event')
  })

  it('should display quantity', () => {
    const wrapper = mount(CartEach, {
      props: { item: mockItem },
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.html()).toContain('2')
  })

  it('should display price', () => {
    const wrapper = mount(CartEach, {
      props: { item: mockItem },
      global: { stubs: { NuxtLink: true } }
    })
    expect(wrapper.html()).toContain('100')
  })

  it('should emit remove event', async () => {
    const wrapper = mount(CartEach, {
      props: { item: mockItem },
      global: { stubs: { NuxtLink: true } }
    })
    wrapper.vm.$emit('remove', mockItem.id)
    expect(wrapper.emitted()).toHaveProperty('remove')
  })
})
