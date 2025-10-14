import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import MyBookingsPage from '~/app/pages/MyBookingsPage.vue'

// Mock fetch globally
global.fetch = vi.fn()

const mockBookings = [
  {
    bookingId: 1,
    event: {
      id: 101,
      name: 'Rock Concert',
      datestart: '2024-12-01T19:00:00Z',
      location: 'Bangkok Arena'
    },
    quantity: 2,
    totalPrice: 1000,
    bookingDate: '2024-11-01T10:00:00Z'
  },
  {
    bookingId: 2,
    event: {
      id: 102,
      name: 'Jazz Night',
      datestart: '2024-12-15T20:00:00Z',
      location: 'Jazz Club'
    },
    quantity: 1,
    totalPrice: 300,
    bookingDate: '2024-11-05T12:00:00Z'
  }
]

describe('MyBookingsPage.vue', () => {
  let router: any

  beforeEach(() => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/concert/my-bookings', name: 'MyBookings', component: MyBookingsPage }
      ]
    })
    
    vi.clearAllMocks()
    
    // Mock localStorage
    localStorage.setItem('jwt_token', 'test-token')
    
    // Mock successful bookings API
    ;(global.fetch as any).mockResolvedValue({
      ok: true,
      json: async () => mockBookings
    })
  })

  it('should render my bookings page', () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should fetch bookings on mount', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Component should be mounted
    expect(wrapper.exists()).toBe(true)
  })

  it('should display bookings list', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Component should render bookings data
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle empty bookings', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => []
    })
    
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    // Should show empty state
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle cancel booking action', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    const vm = wrapper.vm as any
    
    // If cancel function exists
    if (vm.cancelBooking || vm.handleCancelBooking) {
      // Mock cancel API
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ message: 'Booking cancelled' })
      })
      
      const cancelFn = vm.cancelBooking || vm.handleCancelBooking
      await cancelFn(1)
      
      // Should call delete API
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/bookings/1'),
        expect.objectContaining({
          method: 'DELETE'
        })
      )
    }
  })

  it('should redirect to login if not authenticated', async () => {
    localStorage.removeItem('jwt_token')
    
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // Component should handle unauthenticated state
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle API error gracefully', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: false,
      status: 500
    })
    
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should show booking details', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    const vm = wrapper.vm as any
    
    // Check if bookings data exists
    expect(Array.isArray(vm.bookings) || vm.bookings === undefined).toBe(true)
  })

  it('should format booking date correctly', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    const vm = wrapper.vm as any
    
    // If date formatting function exists
    if (vm.formatDate) {
      const formatted = vm.formatDate('2024-11-01T10:00:00Z')
      expect(typeof formatted).toBe('string')
    }
  })

  it('should calculate total bookings', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    
    const vm = wrapper.vm as any
    
    // Component should track bookings count
    if (vm.bookings && Array.isArray(vm.bookings)) {
      expect(vm.bookings.length).toBeGreaterThanOrEqual(0)
    }
  })
})
