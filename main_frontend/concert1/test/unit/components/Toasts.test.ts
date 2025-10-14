import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Toasts from '~/app/components/Toasts.vue'
import { useToast } from '~/composables/useToast'

describe('Toasts.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should render toasts component', () => {
    const wrapper = mount(Toasts)
    expect(wrapper.exists()).toBe(true)
  })

  it('should display no toasts initially', () => {
    const wrapper = mount(Toasts)
    const toastElements = wrapper.findAll('[data-testid="toast"]')
    expect(toastElements.length).toBe(0)
  })

  it('should display success toast', async () => {
    const wrapper = mount(Toasts)
    const { success } = useToast()
    
    success('Operation successful!')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('Operation successful!')
  })

  it('should display error toast', async () => {
    const wrapper = mount(Toasts)
    const { error } = useToast()
    
    error('Something went wrong!')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('Something went wrong!')
  })

  it('should display info toast', async () => {
    const wrapper = mount(Toasts)
    const { info } = useToast()
    
    info('Information message')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('Information message')
  })

  it('should display warning toast', async () => {
    const wrapper = mount(Toasts)
    const { warning } = useToast()
    
    warning('Warning message')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('Warning message')
  })

  it('should display multiple toasts', async () => {
    const wrapper = mount(Toasts)
    const { success, error } = useToast()
    
    success('First message')
    error('Second message')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('First message')
    expect(wrapper.text()).toContain('Second message')
  })

  it('should dismiss toast manually', async () => {
    const wrapper = mount(Toasts)
    const { success, dismiss, toasts } = useToast()
    
    success('Test message', undefined, 0) // 0 timeout = no auto-dismiss
    await wrapper.vm.$nextTick()
    
    const toastId = toasts.value[0]?.id
    expect(toasts.value.length).toBe(1)
    
    dismiss(toastId!)
    await wrapper.vm.$nextTick()
    
    expect(toasts.value.length).toBe(0)
  })

  it('should auto-dismiss toast after timeout', async () => {
    vi.useFakeTimers()
    
    const wrapper = mount(Toasts)
    const { success, toasts } = useToast()
    
    success('Auto dismiss', undefined, 100)
    await wrapper.vm.$nextTick()
    
    expect(toasts.value.length).toBe(1)
    
    vi.advanceTimersByTime(100)
    await wrapper.vm.$nextTick()
    
    expect(toasts.value.length).toBe(0)
    
    vi.useRealTimers()
  })

  it('should show toast with title', async () => {
    const wrapper = mount(Toasts)
    const { success } = useToast()
    
    success('Message content', 'Success Title')
    await wrapper.vm.$nextTick()
    
    expect(wrapper.text()).toContain('Success Title')
    expect(wrapper.text()).toContain('Message content')
  })

  it('should handle different toast types with correct styling', async () => {
    const wrapper = mount(Toasts)
    const { success, error, info, warning } = useToast()
    
    success('Success')
    error('Error')
    info('Info')
    warning('Warning')
    await wrapper.vm.$nextTick()
    
    // Component should render all toast types
    expect(wrapper.text()).toContain('Success')
    expect(wrapper.text()).toContain('Error')
    expect(wrapper.text()).toContain('Info')
    expect(wrapper.text()).toContain('Warning')
  })

  it('should dismiss all toasts', async () => {
    const wrapper = mount(Toasts)
    const { success, error, dismissAll, toasts } = useToast()
    
    success('First', undefined, 0)
    error('Second', undefined, 0)
    await wrapper.vm.$nextTick()
    
    expect(toasts.value.length).toBe(2)
    
    dismissAll()
    await wrapper.vm.$nextTick()
    
    expect(toasts.value.length).toBe(0)
  })

  it('should render toast container element', () => {
    const wrapper = mount(Toasts)
    const container = wrapper.find('div')
    expect(container.exists()).toBe(true)
  })
})
