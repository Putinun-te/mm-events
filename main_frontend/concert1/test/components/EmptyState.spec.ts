import { describe, it, expect } from 'vitest'
import { mount, RouterLinkStub } from '@vue/test-utils'
import EmptyState from '@/components/EmptyState.vue'

describe('EmptyState', () => {
  it('renders with required props', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'No Results Found',
        message: 'Try adjusting your search criteria'
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('No Results Found')
    expect(wrapper.text()).toContain('Try adjusting your search criteria')
  })

  it('renders with default icon', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        message: 'Nothing here'
      }
    })

    expect(wrapper.text()).toContain('📭')
  })

  it('renders with custom icon', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'No Events',
        message: 'No events found',
        icon: '🎫'
      }
    })

    expect(wrapper.text()).toContain('🎫')
    expect(wrapper.text()).not.toContain('📭')
  })

  it('renders action link when provided', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty Cart',
        message: 'Your cart is empty',
        actionText: 'Browse Events',
        actionLink: '/events'
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const link = wrapper.findComponent(RouterLinkStub)
    expect(link.exists()).toBe(true)
    expect(link.props('to')).toBe('/events')
    expect(link.text()).toBe('Browse Events')
  })

  it('does not render action link when not provided', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        message: 'Nothing here'
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const link = wrapper.findComponent(RouterLinkStub)
    expect(link.exists()).toBe(false)
  })

  it('uses default action text', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        message: 'Nothing',
        actionLink: '/home'
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const link = wrapper.findComponent(RouterLinkStub)
    expect(link.text()).toBe('Get Started')
  })

  it('renders slot content', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        message: 'Nothing here'
      },
      slots: {
        default: '<button class="custom-button">Custom Action</button>'
      }
    })

    expect(wrapper.find('.custom-button').exists()).toBe(true)
    expect(wrapper.text()).toContain('Custom Action')
  })

  it('has correct styling classes', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Test',
        message: 'Test message'
      }
    })

    const container = wrapper.find('div')
    expect(container.classes()).toContain('flex')
    expect(container.classes()).toContain('flex-col')
    expect(container.classes()).toContain('items-center')
    expect(container.classes()).toContain('justify-center')
    expect(container.classes()).toContain('text-center')
  })

  it('icon has animation class', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Test',
        message: 'Test'
      }
    })

    const icon = wrapper.find('.text-8xl')
    expect(icon.classes()).toContain('animate-bounce')
  })

  it('title has correct styling', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty State',
        message: 'Message'
      }
    })

    const title = wrapper.find('h2')
    expect(title.classes()).toContain('text-3xl')
    expect(title.classes()).toContain('font-bold')
    expect(title.classes()).toContain('text-gray-900')
  })

  it('message has correct styling', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Title',
        message: 'Test message'
      }
    })

    const message = wrapper.find('p')
    expect(message.classes()).toContain('text-gray-600')
    expect(message.classes()).toContain('max-w-md')
  })

  it('action link has correct styling', () => {
    const wrapper = mount(EmptyState, {
      props: {
        title: 'Empty',
        message: 'Nothing',
        actionLink: '/test'
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const link = wrapper.findComponent(RouterLinkStub)
    expect(link.classes()).toContain('bg-gradient-to-r')
    expect(link.classes()).toContain('from-purple-600')
    expect(link.classes()).toContain('text-white')
    expect(link.classes()).toContain('rounded-lg')
  })
})
