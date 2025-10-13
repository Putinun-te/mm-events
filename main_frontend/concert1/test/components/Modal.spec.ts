import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Modal from '@/components/Modal.vue'

describe('Modal', () => {
  it('renders modal when show is true', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        title: 'Test Modal'
      },
      slots: {
        default: '<p>Modal content here</p>'
      }
    })

    expect(wrapper.find('.fixed.inset-0').exists()).toBe(true)
    expect(wrapper.text()).toContain('Test Modal')
    expect(wrapper.text()).toContain('Modal content here')
  })

  it('does not render modal when show is false', () => {
    const wrapper = mount(Modal, {
      props: {
        show: false
      }
    })

    expect(wrapper.find('.fixed.inset-0').exists()).toBe(false)
  })

  it('renders with default props', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    // Default confirm button text
    const buttons = wrapper.findAll('button')
    expect(buttons[0].text()).toBe('Cancel')
    expect(buttons[1].text()).toBe('Confirm')
  })

  it('renders with custom button text', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        confirmText: 'Yes, Delete',
        cancelText: 'No, Keep It'
      }
    })

    const buttons = wrapper.findAll('button')
    expect(buttons[0].text()).toBe('No, Keep It')
    expect(buttons[1].text()).toBe('Yes, Delete')
  })

  it('renders title when provided', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        title: 'Confirm Action'
      }
    })

    expect(wrapper.find('h3').text()).toBe('Confirm Action')
    expect(wrapper.find('.border-b').exists()).toBe(true)
  })

  it('does not render title section when title is not provided', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    expect(wrapper.find('h3').exists()).toBe(false)
    expect(wrapper.find('.border-b').exists()).toBe(false)
  })

  it('renders slot content', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      },
      slots: {
        default: '<div class="test-content">Custom Content</div>'
      }
    })

    expect(wrapper.find('.test-content').exists()).toBe(true)
    expect(wrapper.text()).toContain('Custom Content')
  })

  it('emits confirm event when confirm button is clicked', async () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const confirmButton = wrapper.findAll('button')[1]
    await confirmButton.trigger('click')

    expect(wrapper.emitted('confirm')).toBeTruthy()
    expect(wrapper.emitted('confirm')?.length).toBe(1)
  })

  it('emits cancel event when cancel button is clicked', async () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const cancelButton = wrapper.findAll('button')[0]
    await cancelButton.trigger('click')

    expect(wrapper.emitted('cancel')).toBeTruthy()
    expect(wrapper.emitted('cancel')?.length).toBe(1)
  })

  it('emits close event when backdrop is clicked', async () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const backdrop = wrapper.find('.fixed.inset-0')
    await backdrop.trigger('click')

    expect(wrapper.emitted('close')).toBeTruthy()
    expect(wrapper.emitted('close')?.length).toBe(1)
  })

  it('does not emit close when clicking inside modal content', async () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        title: 'Test Modal'
      }
    })

    const modalContent = wrapper.find('.bg-white.rounded-2xl')
    await modalContent.trigger('click')

    // Should not emit close when clicking inside modal
    expect(wrapper.emitted('close')).toBeFalsy()
  })

  it('applies custom confirm button color', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        confirmColor: 'bg-red-600 hover:bg-red-700'
      }
    })

    const confirmButton = wrapper.findAll('button')[1]
    expect(confirmButton.classes()).toContain('bg-red-600')
    expect(confirmButton.classes()).toContain('hover:bg-red-700')
  })

  it('applies default confirm button color', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const confirmButton = wrapper.findAll('button')[1]
    expect(confirmButton.classes()).toContain('bg-purple-600')
    expect(confirmButton.classes()).toContain('hover:bg-purple-700')
  })

  it('has correct button order (cancel first, confirm second)', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        cancelText: 'Cancel Action',
        confirmText: 'Confirm Action'
      }
    })

    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(2)
    expect(buttons[0].text()).toBe('Cancel Action')
    expect(buttons[1].text()).toBe('Confirm Action')
  })

  it('has correct styling classes for backdrop', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const backdrop = wrapper.find('.fixed.inset-0')
    expect(backdrop.classes()).toContain('bg-black/50')
    expect(backdrop.classes()).toContain('backdrop-blur-sm')
    expect(backdrop.classes()).toContain('z-50')
    expect(backdrop.classes()).toContain('flex')
    expect(backdrop.classes()).toContain('items-center')
    expect(backdrop.classes()).toContain('justify-center')
  })

  it('has correct styling for modal container', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const modalContainer = wrapper.find('.bg-white.rounded-2xl')
    expect(modalContainer.classes()).toContain('shadow-2xl')
    expect(modalContainer.classes()).toContain('max-w-md')
    expect(modalContainer.classes()).toContain('w-full')
  })

  it('handles multiple rapid emit events', async () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const confirmButton = wrapper.findAll('button')[1]
    
    // Trigger confirm multiple times rapidly
    await confirmButton.trigger('click')
    await confirmButton.trigger('click')
    await confirmButton.trigger('click')

    // Should emit all three times
    expect(wrapper.emitted('confirm')?.length).toBe(3)
  })

  it('renders correctly with all props combined', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true,
        title: 'Delete Confirmation',
        confirmText: 'Delete Now',
        cancelText: 'Keep It',
        confirmColor: 'bg-red-500 hover:bg-red-600'
      },
      slots: {
        default: '<p>Are you sure you want to delete this item?</p>'
      }
    })

    // Check all elements
    expect(wrapper.find('h3').text()).toBe('Delete Confirmation')
    expect(wrapper.text()).toContain('Are you sure you want to delete this item?')
    expect(wrapper.findAll('button')[0].text()).toBe('Keep It')
    expect(wrapper.findAll('button')[1].text()).toBe('Delete Now')
    expect(wrapper.findAll('button')[1].classes()).toContain('bg-red-500')
  })

  it('has correct button styling', () => {
    const wrapper = mount(Modal, {
      props: {
        show: true
      }
    })

    const cancelButton = wrapper.findAll('button')[0]
    const confirmButton = wrapper.findAll('button')[1]

    // Cancel button styling
    expect(cancelButton.classes()).toContain('border-2')
    expect(cancelButton.classes()).toContain('border-gray-300')
    expect(cancelButton.classes()).toContain('text-gray-700')
    expect(cancelButton.classes()).toContain('hover:bg-gray-50')

    // Confirm button styling
    expect(confirmButton.classes()).toContain('text-white')
    expect(confirmButton.classes()).toContain('font-semibold')
  })
})
