import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { RouterLinkStub } from '@vue/test-utils'
import HeroCarousel from '@/components/HeroCarousel.vue'

describe('HeroCarousel', () => {
  const mockEvents = [
    {
      id: '1',
      title: 'Summer Music Festival 2025',
      subtitle: 'Join us for an unforgettable summer experience',
      image: '/images/event1.jpg',
      date: '2025-07-15',
      time: '18:00',
      location: 'Central Park',
      ctaText: 'Get Tickets',
      ctaLink: '/concert/ProductPage/1',
      category: 'Music',
      badge: 'Trending'
    },
    {
      id: '2',
      title: 'Tech Conference 2025',
      subtitle: 'Explore the future of technology',
      image: '/images/event2.jpg',
      date: '2025-08-20',
      time: '09:00',
      location: 'Convention Center',
      ctaText: 'Register Now',
      ctaLink: '/concert/ProductPage/2',
      category: 'Technology'
    },
    {
      id: '3',
      title: 'Art Exhibition',
      subtitle: 'Contemporary art showcase',
      image: '/images/event3.jpg',
      date: '2025-09-10',
      time: '10:00',
      location: 'Art Gallery',
      ctaText: 'Learn More',
      ctaLink: '/concert/ProductPage/3',
      category: 'Art'
    }
  ]

  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renders carousel with first event', () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Summer Music Festival 2025')
    expect(wrapper.text()).toContain('Join us for an unforgettable summer experience')
  })

  it('shows badge when provided', () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Trending')
  })

  it('navigates to next slide', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Initially shows first event
    expect(wrapper.text()).toContain('Summer Music Festival 2025')

    // Find and click next button
    const buttons = wrapper.findAll('button')
    const nextButton = buttons.find(btn => btn.html().includes('chevron-right') || btn.attributes('aria-label')?.includes('Next'))
    
    if (nextButton) {
      await nextButton.trigger('click')
      await flushPromises()
    }

    // Should show second event
    expect(wrapper.text()).toContain('Tech Conference 2025')
  })

  it('navigates to previous slide', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Click previous button (should wrap to last slide)
    const buttons = wrapper.findAll('button')
    const prevButton = buttons.find(btn => btn.html().includes('chevron-left') || btn.attributes('aria-label')?.includes('Previous'))
    
    if (prevButton) {
      await prevButton.trigger('click')
      await flushPromises()
    }

    // Should show last event
    expect(wrapper.text()).toContain('Art Exhibition')
  })

  it('auto-rotates slides when autoRotate is true', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: true,
        interval: 1000
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Initially shows first event
    expect(wrapper.text()).toContain('Summer Music Festival 2025')

    // Fast-forward time
    vi.advanceTimersByTime(1000)
    await flushPromises()

    // Should auto-advance to second event
    expect(wrapper.text()).toContain('Tech Conference 2025')
  })

  it('pauses auto-rotation on mouse enter', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: true,
        interval: 1000
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Trigger mouse enter
    await wrapper.trigger('mouseenter')
    await flushPromises()

    // Advance time
    vi.advanceTimersByTime(2000)
    await flushPromises()

    // Should still show first event (not auto-rotated)
    expect(wrapper.text()).toContain('Summer Music Festival 2025')
  })

  it('resumes auto-rotation on mouse leave', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: true,
        interval: 1000
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Pause
    await wrapper.trigger('mouseenter')
    await flushPromises()

    // Resume
    await wrapper.trigger('mouseleave')
    await flushPromises()

    // Advance time
    vi.advanceTimersByTime(1000)
    await flushPromises()

    // Should auto-advance to second event
    expect(wrapper.text()).toContain('Tech Conference 2025')
  })

  it('displays event category', () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Music')
  })

  it('displays event date and time', () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Check for date elements (format may vary)
    expect(wrapper.html()).toContain('2025-07-15')
    expect(wrapper.html()).toContain('18:00')
  })

  it('displays event location', () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Central Park')
  })

  it('renders CTA button with correct text', () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    expect(wrapper.text()).toContain('Get Tickets')
  })

  it('wraps around when reaching end of slides', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: true,
        interval: 1000
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Advance through all slides
    vi.advanceTimersByTime(3000)
    await flushPromises()

    // Should wrap back to first slide
    expect(wrapper.text()).toContain('Summer Music Festival 2025')
  })

  it('disables auto-rotate when prop is false', async () => {
    const wrapper = mount(HeroCarousel, {
      props: {
        events: mockEvents,
        autoRotate: false
      },
      global: {
        stubs: {
          NuxtLink: RouterLinkStub
        }
      }
    })

    // Initially shows first event
    expect(wrapper.text()).toContain('Summer Music Festival 2025')

    // Advance time
    vi.advanceTimersByTime(10000)
    await flushPromises()

    // Should still show first event (no auto-rotation)
    expect(wrapper.text()).toContain('Summer Music Festival 2025')
  })
})
