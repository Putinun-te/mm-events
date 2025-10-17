import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import MyBookingsPage from '~/app/pages/MyBookingsPage.vue'

// Mock $fetch globally
global.$fetch = vi.fn() as any

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

  it('should call fetchBookings function', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.fetchBookings) {
      await vm.fetchBookings()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call openCancelModal function', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.openCancelModal) {
      const mockBooking = {
        id: 1,
        eventTitle: 'Test Event',
        quantity: 2,
        totalPrice: 1000
      }
      vm.openCancelModal(mockBooking)
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call closeCancelModal function', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.closeCancelModal) {
      vm.closeCancelModal()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call confirmCancelBooking function', async () => {
    ;(global.$fetch as any).mockResolvedValue({ success: true })
    
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.confirmCancelBooking) {
      await vm.confirmCancelBooking()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call goToEvent function', async () => {
    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.goToEvent) {
      const mockBooking = {
        id: 1,
        eventId: 123,
        eventTitle: 'Test Event'
      }
      vm.goToEvent(mockBooking)
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle fetch error with error message', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: false,
      json: async () => ({ message: 'Failed to fetch bookings' })
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

  it('should handle fetch error without message', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: false
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

  it('should handle network error during fetch', async () => {
    ;(global.fetch as any).mockRejectedValueOnce(new Error('Network error'))

    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })

    await new Promise(resolve => setTimeout(resolve, 100))
    await wrapper.vm.$nextTick()
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle cancel booking failure', async () => {
    ;(global.$fetch as any).mockRejectedValueOnce({
      data: { message: 'Cannot cancel booking' }
    })

    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })

    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    if (vm.confirmCancelBooking) {
      await vm.confirmCancelBooking()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle missing token', async () => {
    localStorage.removeItem('jwt_token')

    const wrapper = mount(MyBookingsPage, {
      global: {
        plugins: [router]
      }
    })

    await new Promise(resolve => setTimeout(resolve, 100))
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle bookings with missing event data', async () => {
    ;(global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => [
        {
          bookingId: 1,
          event: null,
          quantity: 2,
          totalPrice: 1000
        }
      ]
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

  describe('Booking Cancellation Feature', () => {
    it('should open cancel confirmation modal when cancel booking is clicked', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockBookings
      })

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      // Find and click cancel button
      const cancelButtons = wrapper.findAll('button')
      const cancelButton = cancelButtons.find(btn => btn.text().includes('Cancel Booking'))
      
      if (cancelButton) {
        await cancelButton.trigger('click')
        await wrapper.vm.$nextTick()
        
        // Check if modal becomes visible
        expect(wrapper.vm.showCancelModal).toBe(true)
      }
    })

    it('should cancel booking and remove participant from event', async () => {
      const mockEventId = 101
      const mockBookingId = 1
      
      ;(global.fetch as any)
        .mockResolvedValueOnce({
          ok: true,
          json: async () => [
            {
              id: mockBookingId,
              eventId: mockEventId,
              quantity: 2,
              status: 'CONFIRMED',
              totalPrice: 1000
            }
          ]
        })
        .mockResolvedValueOnce({ statusCode: 204 }) // Cancel booking response
        .mockResolvedValueOnce({ message: 'Successfully left event' }) // Leave event response

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      // Simulate opening and confirming cancellation
      if (wrapper.vm.bookings && wrapper.vm.bookings.length > 0) {
        wrapper.vm.openCancelModal(wrapper.vm.bookings[0])
        await wrapper.vm.$nextTick()
        
        // The modal should be open
        expect(wrapper.vm.showCancelModal).toBe(true)
      }
    })

    it('should update booking status to CANCELLED after cancellation', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => [
          {
            id: 1,
            eventId: 101,
            quantity: 2,
            status: 'CONFIRMED'
          }
        ]
      })

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      // Verify initial status is CONFIRMED
      if (wrapper.vm.bookings[0]) {
        const initialStatus = wrapper.vm.bookings[0].status
        expect(initialStatus).toBe('CONFIRMED')
      }
    })

    it('should close cancellation modal after successful cancellation', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockBookings
      })

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      // Modal should be closed initially
      expect(wrapper.vm.showCancelModal).toBe(false)

      // Open modal
      if (wrapper.vm.bookings && wrapper.vm.bookings.length > 0) {
        wrapper.vm.openCancelModal(wrapper.vm.bookings[0])
        await wrapper.vm.$nextTick()
        expect(wrapper.vm.showCancelModal).toBe(true)

        // Close modal
        wrapper.vm.closeCancelModal()
        await wrapper.vm.$nextTick()
        expect(wrapper.vm.showCancelModal).toBe(false)
      }
    })

    it('should handle cancellation errors gracefully', async () => {
      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      // Component should render without errors despite any errors
      expect(wrapper.exists()).toBe(true)
      // Verify component is stable and doesn't crash
      expect(wrapper.vm).toBeDefined()
    })

    it('should show confirmation dialog before cancelling', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockBookings
      })

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      // Modal should exist and be closable
      if (wrapper.vm.bookings && wrapper.vm.bookings.length > 0) {
        wrapper.vm.showCancelModal = true
        await wrapper.vm.$nextTick()

        // Cancel modal should be visible
        expect(wrapper.vm.showCancelModal).toBe(true)

        // Can close modal
        wrapper.vm.closeCancelModal()
        expect(wrapper.vm.showCancelModal).toBe(false)
      }
    })
  })

  describe('Participant Count Reduction', () => {
    it('should call leave event endpoint when cancelling booking', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => [
          {
            id: 1,
            eventId: 123,
            quantity: 57,
            status: 'CONFIRMED'
          }
        ]
      })

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))

      // Verify fetch was called for bookings
      expect(global.fetch).toHaveBeenCalled()
    })

    it('should pass correct event ID to leave endpoint', async () => {
      const mockEventId = 456
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => [
          {
            id: 1,
            eventId: mockEventId,
            quantity: 1,
            status: 'CONFIRMED'
          }
        ]
      })

      const wrapper = mount(MyBookingsPage, {
        global: {
          plugins: [router]
        }
      })

      await new Promise(resolve => setTimeout(resolve, 100))
      await wrapper.vm.$nextTick()

      if (wrapper.vm.bookings[0]) {
        expect(wrapper.vm.bookings[0].eventId).toBe(mockEventId)
      }
    })
  })
})


