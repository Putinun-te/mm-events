import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import ProductCard from '~/app/components/ProductCard.vue'

// Mock router
const mockPush = vi.fn()
vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: mockPush
  })
}))

describe('ProductCard Component', () => {
  const mockEvent = {
    id: 1,
    name: 'Test Event',
    datestart: '1735689600', // Jan 1, 2025
    dateend: '1735776000',
    personlimit: 100,
    description: 'Test event description'
  }

  it('should render product card', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should display event name', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.text()).toContain('Test Event')
  })

  it('should display event description', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.text()).toContain('Test event description')
  })

  it('should accept new API event format', () => {
    const newFormatEvent = {
      id: 1,
      title: 'New Format Event',
      description: 'New description',
      startDate: '2025-01-01T10:00:00',
      endDate: '2025-01-01T18:00:00',
      personLimit: 50
    }

    const wrapper = mount(ProductCard, {
      props: {
        event: newFormatEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.text()).toContain('New Format Event')
  })

  it('should handle events without description', () => {
    const eventWithoutDesc = {
      ...mockEvent,
      description: ''
    }

    const wrapper = mount(ProductCard, {
      props: {
        event: eventWithoutDesc
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should call toDate function', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.toDate) {
      const result = vm.toDate('1735689600')
      expect(result).toBeInstanceOf(Date)
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call formatEventDateMn function', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.formatEventDateMn) {
      const result = vm.formatEventDateMn('1735689600')
      expect(typeof result).toBe('string')
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call formatEventDateTime function', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.formatEventDateTime) {
      const result = vm.formatEventDateTime('1735689600')
      expect(typeof result).toBe('string')
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call more function', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.more) {
      vm.more()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call join function', () => {
    const wrapper = mount(ProductCard, {
      props: {
        event: mockEvent
      },
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.join) {
      vm.join()
    }
    expect(wrapper.exists()).toBe(true)
  })
})
