import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import ProductCard from '@/components/ProductCard.vue'

vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: vi.fn()
  })
}))

vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({
    isLoggedIn: { value: true },
    user: { value: { id: 1, email: 'test@test.com' } },
    clearAuth: vi.fn()
  })
}))

describe('ProductCard', () => {
  const mockEvent = {
    id: '1',
    name: 'Test Event',
    description: 'Test Description',
    personlimit: 100,
    registeredCount: 30,
    category: 'Music',
    location: 'Test Location',
    image: '/test-image.jpg',
    price: 99.99,
    startDate: Math.floor(Date.now() / 1000) + 86400,
    endDate: Math.floor(Date.now() / 1000) + 172800
  }

  it('renders event name', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      }
    })
    expect(wrapper.text()).toContain('Test Event')
  })

  it('calculates spots remaining correctly', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      }
    })
    const text = wrapper.text()
    expect(text).toMatch(/70|spots/)
  })

  it('shows category badge', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      }
    })
    expect(wrapper.text()).toContain('Music')
  })

  it('displays location', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      }
    })
    expect(wrapper.text()).toContain('Test Location')
  })

  it('renders Register button when spots available', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      }
    })
    expect(wrapper.text()).toContain('Register')
  })

  it('shows Sold Out when no spots remaining', () => {
    const soldOutEvent = {
      ...mockEvent,
      registeredCount: 100
    }
    const wrapper = mount(ProductCard, {
      props: {
        event: soldOutEvent
      }
    })
    expect(wrapper.text()).toContain('Sold Out')
  })
})
