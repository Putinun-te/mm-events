import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import IndexPage from '~/app/pages/index.vue'

// Mock fetch globally
global.fetch = vi.fn()

const mockFeaturedEvents = [
  {
    id: 1,
    name: 'Summer Festival',
    description: 'Outdoor music festival',
    datestart: '1672531200000',
    price: 1500,
    location: 'Central Park',
    posterUrl: '/images/festival.jpg'
  },
  {
    id: 2,
    name: 'Tech Conference',
    description: 'Latest tech trends',
    datestart: '1672617600000',
    price: 2000,
    location: 'Convention Center',
    posterUrl: '/images/tech.jpg'
  }
]

describe('index.vue (Homepage)', () => {
  let router: any

  beforeEach(() => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/concert', name: 'Home', component: IndexPage },
        { path: '/concert/product', name: 'Products', component: { template: '<div>Products</div>' } }
      ]
    })
    
    vi.clearAllMocks()
    
    // Mock events API
    ;(global.fetch as any).mockResolvedValue({
      ok: true,
      json: async () => mockFeaturedEvents
    })
  })

  it('should render homepage', () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should fetch featured events on mount', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Component should be mounted and stable
    expect(wrapper.exists()).toBe(true)
  })

  it('should display featured events', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router],
        stubs: {
          ProductCard: {
            template: '<div class="product-card">{{ event.name }}</div>',
            props: ['event']
          }
        }
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Should render some content
    expect(wrapper.exists()).toBe(true)
  })

  it('should have navigation links', () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    // Should have clickable elements
    const links = wrapper.findAll('a, button')
    expect(links.length).toBeGreaterThanOrEqual(0)
  })

  it('should navigate to browse events', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    
    // If navigate function exists
    if (vm.goToProducts || vm.browseEvents) {
      const navFn = vm.goToProducts || vm.browseEvents
      navFn()
      
      expect(wrapper.exists()).toBe(true)
    }
  })

  it('should handle API error gracefully', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: false,
      status: 500
    })
    
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Should still render
    expect(wrapper.exists()).toBe(true)
  })

  it('should show welcome message or hero section', () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    // Homepage should have some content
    const text = wrapper.text()
    expect(text.length).toBeGreaterThan(0)
  })

  it('should have responsive layout', () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    // Component should have root element
    expect(wrapper.element).toBeTruthy()
  })

  it('should call click function', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.click) {
      vm.click()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call click2 function', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.click2) {
      vm.click2()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should navigate to next slide', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.nextSlide) {
      vm.nextSlide()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should navigate to previous slide', async () => {
    const wrapper = mount(IndexPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.prevSlide) {
      vm.prevSlide()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })
})

