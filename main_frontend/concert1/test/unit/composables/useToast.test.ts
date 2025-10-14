import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'
import { useToast } from '~/app/composables/useToast'

describe('useToast Composable', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    const { dismissAll } = useToast()
    dismissAll()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('should add success toast', () => {
    const { success, toasts } = useToast()
    success('Test success message', 'Success!')
    
    expect(toasts.value.length).toBe(1)
    expect(toasts.value[0].type).toBe('success')
    expect(toasts.value[0].message).toBe('Test success message')
    expect(toasts.value[0].title).toBe('Success!')
  })

  it('should add error toast', () => {
    const { error, toasts } = useToast()
    error('Test error message', 'Error!')
    
    expect(toasts.value.length).toBe(1)
    expect(toasts.value[0].type).toBe('error')
    expect(toasts.value[0].message).toBe('Test error message')
  })

  it('should add info toast', () => {
    const { info, toasts } = useToast()
    info('Test info message')
    
    expect(toasts.value.length).toBe(1)
    expect(toasts.value[0].type).toBe('info')
  })

  it('should add warning toast', () => {
    const { warning, toasts } = useToast()
    warning('Test warning message')
    
    expect(toasts.value.length).toBe(1)
    expect(toasts.value[0].type).toBe('warning')
  })

  it('should dismiss toast by id', () => {
    const { success, dismiss, toasts } = useToast()
    success('Toast 1')
    success('Toast 2')
    
    const firstId = toasts.value[0].id
    dismiss(firstId)
    
    expect(toasts.value.length).toBe(1)
    expect(toasts.value[0].message).toBe('Toast 2')
  })

  it('should dismiss all toasts', () => {
    const { success, error, dismissAll, toasts } = useToast()
    success('Toast 1')
    error('Toast 2')
    success('Toast 3')
    
    expect(toasts.value.length).toBe(3)
    
    dismissAll()
    
    expect(toasts.value.length).toBe(0)
  })

  it('should auto-dismiss toast after timeout', () => {
    const { success, toasts } = useToast()
    success('Auto dismiss', 'Test', 1000)
    
    expect(toasts.value.length).toBe(1)
    
    vi.advanceTimersByTime(1000)
    
    expect(toasts.value.length).toBe(0)
  })

  it('should handle multiple toasts with different timeouts', () => {
    const { success, error, toasts } = useToast()
    success('Toast 1', undefined, 1000)
    error('Toast 2', undefined, 2000)
    
    expect(toasts.value.length).toBe(2)
    
    vi.advanceTimersByTime(1000)
    expect(toasts.value.length).toBe(1)
    expect(toasts.value[0].message).toBe('Toast 2')
    
    vi.advanceTimersByTime(1000)
    expect(toasts.value.length).toBe(0)
  })

  it('should not auto-dismiss when timeout is 0', () => {
    const { push, toasts } = useToast()
    push('Persistent toast', 'info', 0)
    
    expect(toasts.value.length).toBe(1)
    
    vi.advanceTimersByTime(10000)
    
    expect(toasts.value.length).toBe(1)
  })
})
