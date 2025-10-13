import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { RouterLinkStub } from '@vue/test-utils'
import Footer from '@/components/Footer.vue'

describe('Footer', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders footer with copyright year', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const currentYear = new Date().getFullYear()
    expect(wrapper.text()).toContain(currentYear.toString())
    expect(wrapper.text()).toContain('EventHub')
  })

  it('renders newsletter signup form', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
    expect(wrapper.text()).toContain('newsletter')
  })

  it('validates email before subscription', async () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Try to submit with invalid email
    await wrapper.find('input[type="email"]').setValue('invalid-email')
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Please enter a valid email address')
  })

  it('validates empty email field', async () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Try to submit with empty email
    await wrapper.find('form').trigger('submit.prevent')
    await flushPromises()

    expect(wrapper.text()).toContain('Please enter a valid email address')
  })

  it('successfully subscribes with valid email', async () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('input[type="email"]').setValue('test@example.com')
    await wrapper.find('form').trigger('submit.prevent')
    
    // Wait for the subscription process (1.5s delay)
    await new Promise(resolve => setTimeout(resolve, 1600))
    await flushPromises()

    expect(wrapper.text()).toContain('Successfully subscribed')
  })

  it('clears email field after successful subscription', async () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('input[type="email"]').setValue('test@example.com')
    await wrapper.find('form').trigger('submit.prevent')
    
    await new Promise(resolve => setTimeout(resolve, 1600))
    await flushPromises()

    expect((wrapper.find('input[type="email"]').element as HTMLInputElement).value).toBe('')
  })

  it('disables submit button during subscription', async () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    await wrapper.find('input[type="email"]').setValue('test@example.com')
    
    const form = wrapper.find('form')
    form.trigger('submit.prevent')
    await wrapper.vm.$nextTick()

    // Button should be disabled during loading
    const button = wrapper.find('button[type="submit"]')
    expect(button.attributes('disabled')).toBeDefined()
  })

  it('renders company links', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('About Us')
    expect(wrapper.text()).toContain('Careers')
    expect(wrapper.text()).toContain('Partnerships')
  })

  it('renders events links', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Browse Events')
    expect(wrapper.text()).toContain('Create Event')
    expect(wrapper.text()).toContain('Event Categories')
  })

  it('renders support links', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Help Center')
    expect(wrapper.text()).toContain('FAQ')
    expect(wrapper.text()).toContain('Contact Us')
  })

  it('renders legal links', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Privacy Policy')
    expect(wrapper.text()).toContain('Terms of Service')
  })

  it('renders social media links', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Check for social media icons/links (adjust based on actual implementation)
    const links = wrapper.findAll('a')
    expect(links.length).toBeGreaterThan(0)
  })

  it('has correct link structure', () => {
    const wrapper = mount(Footer, {
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    const routerLinks = wrapper.findAllComponents(RouterLinkStub)
    expect(routerLinks.length).toBeGreaterThan(10) // Should have multiple navigation links
  })
})
