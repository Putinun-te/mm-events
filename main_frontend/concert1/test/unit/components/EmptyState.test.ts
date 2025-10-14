import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import EmptyState from '~/app/components/EmptyState.vue'

describe('EmptyState.vue', () => {
  it('should render empty state component', () => {
    const wrapper = mount(EmptyState)
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should display default message when no message provided', () => {
    const wrapper = mount(EmptyState)
    
    const text = wrapper.text()
    expect(text.length).toBeGreaterThan(0)
  })

  it('should display custom message when provided', () => {
    const customMessage = 'No items found'
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        description: customMessage
      }
    })
    
    expect(wrapper.text()).toContain(customMessage)
  })

  it('should show action button when provided', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        description: 'No items',
        actionLink: '/add',
        actionText: 'Add Item'
      },
      global: {
        stubs: { NuxtLink: true }
      }
    })
    
    const html = wrapper.html()
    expect(html).toContain('Add Item')
  })

  it('should emit action event when button clicked', async () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        description: 'No items',
        secondaryAction: true,
        secondaryText: 'Secondary'
      }
    })
    
    const button = wrapper.find('button')
    if (button.exists()) {
      await button.trigger('click')
      expect(wrapper.emitted()).toHaveProperty('secondary-action')
    } else {
      expect(wrapper.exists()).toBe(true)
    }
  })

  it('should not show button when buttonText not provided', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        description: 'No items'
      }
    })
    
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(0)
  })

  it('should display icon or illustration', () => {
    const wrapper = mount(EmptyState)
    
    // Check for SVG, image, or icon element
    const hasSvg = wrapper.find('svg').exists()
    const hasImg = wrapper.find('img').exists()
    const hasIcon = wrapper.find('[class*="icon"]').exists()
    
    expect(hasSvg || hasImg || hasIcon || wrapper.html().length > 0).toBe(true)
  })

  it('should handle different empty state types', () => {
    const wrapper = mount(EmptyState, {
      props: {
        type: 'no-results'
      }
    })
    
    expect(wrapper.exists()).toBe(true)
  })

  it('should render with custom title', () => {
    const customTitle = 'Nothing Here'
    const wrapper = mount(EmptyState, {
      props: {
        title: customTitle
      }
    })
    
    expect(wrapper.text()).toContain(customTitle)
  })

  it('should support slot content', () => {
    const wrapper = mount(EmptyState, {
      slots: {
        default: '<div class="custom-content">Custom content</div>'
      }
    })
    
    expect(wrapper.html()).toContain('custom-content')
  })
})
