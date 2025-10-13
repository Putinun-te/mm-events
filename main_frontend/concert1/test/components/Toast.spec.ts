import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Toast from '@/components/Toast.vue'

describe('Toast', () => {
  it('renders toast when show is true', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Test notification'
      }
    })

    expect(wrapper.find('.fixed.top-20').exists()).toBe(true)
    expect(wrapper.text()).toContain('Test notification')
  })

  it('does not render toast when show is false', () => {
    const wrapper = mount(Toast, {
      props: {
        show: false,
        message: 'Hidden message'
      }
    })

    expect(wrapper.find('.fixed.top-20').exists()).toBe(false)
  })

  it('renders with success type by default', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Success message'
      }
    })

    // Should not have explicit type, defaults to info
    expect(wrapper.text()).toContain('ℹ️')
  })

  it('renders success toast with correct styling', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        type: 'success',
        message: 'Operation successful!'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('bg-green-50')
    expect(toastElement.classes()).toContain('border-green-200')
    expect(toastElement.classes()).toContain('text-green-800')
    expect(wrapper.text()).toContain('✅')
    expect(wrapper.text()).toContain('Operation successful!')
  })

  it('renders error toast with correct styling', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        type: 'error',
        message: 'Something went wrong!'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('bg-red-50')
    expect(toastElement.classes()).toContain('border-red-200')
    expect(toastElement.classes()).toContain('text-red-800')
    expect(wrapper.text()).toContain('❌')
    expect(wrapper.text()).toContain('Something went wrong!')
  })

  it('renders info toast with correct styling', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        type: 'info',
        message: 'Information for you'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('bg-blue-50')
    expect(toastElement.classes()).toContain('border-blue-200')
    expect(toastElement.classes()).toContain('text-blue-800')
    expect(wrapper.text()).toContain('ℹ️')
    expect(wrapper.text()).toContain('Information for you')
  })

  it('renders warning toast with correct styling', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        type: 'warning',
        message: 'Warning: Check your input'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('bg-yellow-50')
    expect(toastElement.classes()).toContain('border-yellow-200')
    expect(toastElement.classes()).toContain('text-yellow-800')
    expect(wrapper.text()).toContain('⚠️')
    expect(wrapper.text()).toContain('Warning: Check your input')
  })

  it('displays the correct icon for each type', () => {
    const types: Array<'success' | 'error' | 'info' | 'warning'> = ['success', 'error', 'info', 'warning']
    const icons = {
      success: '✅',
      error: '❌',
      info: 'ℹ️',
      warning: '⚠️'
    }

    types.forEach((type) => {
      const wrapper = mount(Toast, {
        props: {
          show: true,
          type,
          message: `${type} message`
        }
      })

      expect(wrapper.text()).toContain(icons[type])
    })
  })

  it('emits close event when close button is clicked', async () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Test message'
      }
    })

    const closeButton = wrapper.find('button')
    await closeButton.trigger('click')

    expect(wrapper.emitted('close')).toBeTruthy()
    expect(wrapper.emitted('close')?.length).toBe(1)
  })

  it('has close button with correct text', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Test message'
      }
    })

    const closeButton = wrapper.find('button')
    expect(closeButton.text()).toBe('×')
  })

  it('has correct positioning classes', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Positioned toast'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('fixed')
    expect(toastElement.classes()).toContain('top-20')
    expect(toastElement.classes()).toContain('right-4')
    expect(toastElement.classes()).toContain('z-50')
  })

  it('has correct layout classes', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Layout test'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('flex')
    expect(toastElement.classes()).toContain('items-center')
    expect(toastElement.classes()).toContain('gap-3')
  })

  it('has correct styling classes', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Style test'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('max-w-md')
    expect(toastElement.classes()).toContain('p-4')
    expect(toastElement.classes()).toContain('rounded-lg')
    expect(toastElement.classes()).toContain('shadow-2xl')
    expect(toastElement.classes()).toContain('border-2')
  })

  it('renders message in paragraph element', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Message in paragraph'
      }
    })

    const paragraph = wrapper.find('p')
    expect(paragraph.exists()).toBe(true)
    expect(paragraph.text()).toBe('Message in paragraph')
    expect(paragraph.classes()).toContain('flex-1')
    expect(paragraph.classes()).toContain('font-medium')
  })

  it('icon has correct styling', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        type: 'success',
        message: 'Icon styling test'
      }
    })

    const icon = wrapper.find('span')
    expect(icon.classes()).toContain('text-2xl')
  })

  it('close button has correct styling', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Button styling test'
      }
    })

    const closeButton = wrapper.find('button')
    expect(closeButton.classes()).toContain('text-gray-500')
    expect(closeButton.classes()).toContain('hover:text-gray-700')
    expect(closeButton.classes()).toContain('font-bold')
    expect(closeButton.classes()).toContain('text-xl')
  })

  it('handles long messages', () => {
    const longMessage = 'This is a very long message that should be displayed properly in the toast notification component without breaking the layout or causing any issues with the styling.'
    
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: longMessage
      }
    })

    expect(wrapper.text()).toContain(longMessage)
    expect(wrapper.find('.max-w-md').exists()).toBe(true) // max-width constraint
  })

  it('handles special characters in message', () => {
    const specialMessage = 'Message with <html> & "quotes" and \'apostrophes\''
    
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: specialMessage
      }
    })

    expect(wrapper.text()).toContain(specialMessage)
  })

  it('can emit close multiple times', async () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Multiple close test'
      }
    })

    const closeButton = wrapper.find('button')
    
    await closeButton.trigger('click')
    await closeButton.trigger('click')
    await closeButton.trigger('click')

    expect(wrapper.emitted('close')?.length).toBe(3)
  })

  it('renders correctly with all elements present', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        type: 'error',
        message: 'Complete toast test'
      }
    })

    // Check all structural elements
    expect(wrapper.find('span').exists()).toBe(true) // icon
    expect(wrapper.find('p').exists()).toBe(true) // message
    expect(wrapper.find('button').exists()).toBe(true) // close button
  })

  it('has animation class', () => {
    const wrapper = mount(Toast, {
      props: {
        show: true,
        message: 'Animation test'
      }
    })

    const toastElement = wrapper.find('.fixed.top-20')
    expect(toastElement.classes()).toContain('animate-slide-in')
  })
})
