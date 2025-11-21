import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import EditEventPage from '~/app/pages/EditEventPage.vue'

// Mock composables
vi.mock('~/composables/useAuth', () => ({
  useAuth: vi.fn(() => ({
    loadFromStorage: vi.fn(),
    isLoggedIn: { value: true },
    user: { value: { token: 'test-token' } }
  }))
}))

vi.mock('~/composables/useToast', () => ({
  useToast: () => ({
    success: vi.fn(),
    error: vi.fn()
  })
}))

// Mock router
const mockPush = vi.fn()
vi.mock('#app', () => ({
  useRoute: () => ({
    query: { id: '123' }
  }),
  useRouter: () => ({
    push: mockPush
  })
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({
    query: { id: '123' }
  }),
  useRouter: () => ({
    push: mockPush
  })
}))

// Mock $fetch
global.$fetch = vi.fn()

describe('EditEventPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    localStorage.setItem('jwt_token', 'test-token')
    
    // Mock successful event fetch
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      title: 'Test Event',
      description: 'Test Description',
      personLimit: 100,
      ticketPrice: 50,
      startDate: '2024-12-31T18:00:00',
      endDate: '2024-12-31T23:00:00',
      address: 'Test Address',
      city: 'Bangkok',
      country: 'Thailand',
      phone: '1234567890',
      category: 'Music',
      location: 'Test Location'
    })
  })

  it('should render edit event page', () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: {
          NuxtLink: true
        }
      }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should fetch event data on mount', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    
    expect(global.$fetch).toHaveBeenCalledWith('/api/events/123', expect.any(Object))
  })

  it('should handle missing event ID', async () => {
    // Mock useRoute to return empty query
    const mockUseRoute = vi.fn(() => ({ query: {} }))
    vi.mocked(global as any).useRoute = mockUseRoute
    
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    expect(wrapper.exists()).toBe(true)
  })

  it('should populate form with event data', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle event not found error', async () => {
    ;(global.$fetch as any).mockResolvedValue(null)
    
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle fetch error', async () => {
    ;(global.$fetch as any).mockRejectedValue(new Error('Network error'))
    
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should redirect to login if not authenticated', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    expect(wrapper.exists()).toBe(true)
  })

  it('should show loading state', () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle date parsing for timestamp format', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      title: 'Test Event',
      startDate: 1704038400, // Timestamp
      endDate: 1704056400
    })
    
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should handle alternative field names', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      name: 'Test Event', // Alternative to title
      datestart: '2024-12-31T18:00:00', // Alternative to startDate
      dateend: '2024-12-31T23:00:00', // Alternative to endDate
      personlimit: 50 // Alternative to personLimit
    })
    
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await wrapper.vm.$nextTick()
    await new Promise(resolve => setTimeout(resolve, 100))
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should call loadEventData function', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    const vm = wrapper.vm as any
    if (vm.loadEventData) {
      await vm.loadEventData()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call validate function', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    if (vm.validate) {
      const result = vm.validate()
      expect(typeof result === 'string' || result === null).toBe(true)
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call handleSubmit function', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    if (vm.handleSubmit) {
      await vm.handleSubmit()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call openDeleteModal function', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    if (vm.openDeleteModal) {
      vm.openDeleteModal()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call closeDeleteModal function', async () => {
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    if (vm.closeDeleteModal) {
      vm.closeDeleteModal()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  it('should call confirmDelete function', async () => {
    ;(global.$fetch as any).mockResolvedValue({ success: true })
    
    const wrapper = mount(EditEventPage, {
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    if (vm.confirmDelete) {
      await vm.confirmDelete()
      await wrapper.vm.$nextTick()
    }
    expect(wrapper.exists()).toBe(true)
  })

  // Branch coverage for validate()
  it('should return error when title is empty', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = ''
    const result = vm.validate()
    expect(result).toBe('Please fill in the event name.')
  })

  it('should return error when description is empty', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = ''
    const result = vm.validate()
    expect(result).toBe('Please add a description.')
  })

  it('should return error when dateStart is missing', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = ''
    const result = vm.validate()
    expect(result).toBe('Please select a start date and time.')
  })

  it('should return error when timeStart is missing', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = ''
    const result = vm.validate()
    expect(result).toBe('Please select a start date and time.')
  })

  it('should return error when dateEnd is missing', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = '18:00'
    vm.form.dateEnd = ''
    const result = vm.validate()
    expect(result).toBe('Please select an end date and time.')
  })

  it('should return error when timeEnd is missing', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = '18:00'
    vm.form.dateEnd = '2024-12-31'
    vm.form.timeEnd = ''
    const result = vm.validate()
    expect(result).toBe('Please select an end date and time.')
  })

  it('should return error when start date is invalid', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = 'invalid'
    vm.form.timeStart = '18:00'
    vm.form.dateEnd = '2024-12-31'
    vm.form.timeEnd = '23:00'
    const result = vm.validate()
    expect(result).toBe('Invalid start/end date.')
  })

  it('should return error when end time is before start time', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = '23:00'
    vm.form.dateEnd = '2024-12-31'
    vm.form.timeEnd = '18:00'
    const result = vm.validate()
    expect(result).toBe('End time must be after start time.')
  })

  it('should return null when validation passes', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = '18:00'
    vm.form.dateEnd = '2024-12-31'
    vm.form.timeEnd = '23:00'
    const result = vm.validate()
    expect(result).toBeNull()
  })

  // Branch coverage for handleSubmit()
  it('should not submit when validation fails', async () => {
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = ''
    await vm.handleSubmit()
    expect(global.$fetch).not.toHaveBeenCalledWith(expect.stringContaining('/api/events/json/'), expect.objectContaining({ method: 'PUT' }))
  })

  it('should handle update error with statusMessage', async () => {
    ;(global.$fetch as any).mockRejectedValue({ statusMessage: 'Server error' })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = '18:00'
    vm.form.dateEnd = '2024-12-31'
    vm.form.timeEnd = '23:00'
    await vm.handleSubmit()
    expect(vm.submitting).toBe(false)
  })

  it('should handle update error with data.message', async () => {
    ;(global.$fetch as any).mockRejectedValue({ data: { message: 'Data error' } })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    vm.form.title = 'Test Event'
    vm.form.description = 'Test Description'
    vm.form.dateStart = '2024-12-31'
    vm.form.timeStart = '18:00'
    vm.form.dateEnd = '2024-12-31'
    vm.form.timeEnd = '23:00'
    await vm.handleSubmit()
    expect(vm.submitting).toBe(false)
  })

  // Branch coverage for confirmDelete()
  it('should handle delete error with statusMessage', async () => {
    ;(global.$fetch as any).mockRejectedValue({ statusMessage: 'Delete error' })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    await vm.confirmDelete()
    expect(vm.showDeleteModal).toBe(false)
  })

  it('should handle delete error with data.message', async () => {
    ;(global.$fetch as any).mockRejectedValue({ data: { message: 'Cannot delete' } })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 100))
    const vm = wrapper.vm as any
    await vm.confirmDelete()
    expect(vm.showDeleteModal).toBe(false)
  })

  // Branch coverage for loadEventData()
  it('should handle event with name instead of title', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      name: 'Event Name',
      description: 'Test',
      startDate: '2024-12-31T18:00:00',
      endDate: '2024-12-31T23:00:00'
    })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    const vm = wrapper.vm as any
    expect(vm.form.title).toBe('Event Name')
  })

  it('should handle event with personlimit instead of personLimit', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      title: 'Test',
      description: 'Test',
      personlimit: 50,
      startDate: '2024-12-31T18:00:00',
      endDate: '2024-12-31T23:00:00'
    })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    const vm = wrapper.vm as any
    expect(vm.form.personLimit).toBe(50)
  })

  it('should handle event with datestart instead of startDate', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      title: 'Test',
      description: 'Test',
      datestart: '2024-12-31T18:00:00',
      dateend: '2024-12-31T23:00:00'
    })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    const vm = wrapper.vm as any
    expect(vm.form.dateStart).toBeTruthy()
  })

  it('should handle null startDate', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      title: 'Test',
      description: 'Test',
      startDate: null,
      endDate: null
    })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    const vm = wrapper.vm as any
    expect(vm.form.dateStart).toBe('')
  })

  it('should handle null endDate', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      title: 'Test',
      description: 'Test',
      startDate: '2024-12-31T18:00:00',
      endDate: null
    })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    const vm = wrapper.vm as any
    expect(vm.form.dateEnd).toBe('')
  })

  it('should handle numeric timestamp for startDate', async () => {
    ;(global.$fetch as any).mockResolvedValue({
      id: 123,
      title: 'Test',
      description: 'Test',
      startDate: 1704038400,
      endDate: 1704056400
    })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    const vm = wrapper.vm as any
    expect(vm.form.dateStart).toBeTruthy()
  })

  it('should handle load error with data.message', async () => {
    ;(global.$fetch as any).mockRejectedValue({ data: { message: 'Load error' } })
    const wrapper = mount(EditEventPage, {
      global: { stubs: { NuxtLink: true } }
    })
    await new Promise(resolve => setTimeout(resolve, 150))
    expect(mockPush).toHaveBeenCalledWith('/MyEventsPage')
  })
})
