import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'

// Venue map on the event detail page (app/pages/product-page-detail/[id].vue).
const { renderVenueMap } = vi.hoisted(() => {
  const g = globalThis as any
  g.definePageMeta = () => {}
  g.useRoute = () => ({ params: { id: '7' }, query: {}, path: '/product-page-detail/7' })
  g.$fetch = () => Promise.resolve(null)
  return { renderVenueMap: vi.fn() }
})

vi.mock('~/app/composables/useVenueMap', async () => {
  const actual = await vi.importActual<typeof import('~/app/composables/useVenueMap')>('~/app/composables/useVenueMap')
  return { ...actual, renderVenueMap }
})

vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({ loadFromStorage: vi.fn(), isLoggedIn: { value: true }, logout: vi.fn() })
}))

vi.mock('~/composables/useToast', () => ({
  useToast: () => ({ success: vi.fn(), error: vi.fn(), info: vi.fn(), warning: vi.fn() })
}))

vi.mock('vue-router', async () => {
  const actual = await vi.importActual<any>('vue-router')
  return { ...actual, useRouter: () => ({ push: vi.fn(), back: vi.fn() }) }
})

import EventDetailPage from '~/app/pages/product-page-detail/[id].vue'

const event = {
  id: 7,
  title: 'Jazz Night',
  location: 'Main Hall',
  city: 'Bangkok',
  country: 'Thailand',
  ticketPrice: 25,
  personLimit: 100,
  participantsCount: 0,
  startDate: '2030-05-01T19:00:00',
  endDate: '2030-05-01T22:00:00'
}

describe('event detail venue map', () => {
  beforeEach(() => {
    renderVenueMap.mockReset()
    window.history.replaceState({ event }, '')
  })

  it('draws the map for the event venue', async () => {
    renderVenueMap.mockResolvedValue({ found: true, map: {} })

    const wrapper = mount(EventDetailPage, { global: { stubs: { NuxtLink: true } } })
    await flushPromises()

    expect(renderVenueMap).toHaveBeenCalledWith(wrapper.find('#map').element, 'Main Hall, Bangkok, Thailand')
    expect(wrapper.text()).not.toContain('Could not find this venue on the map.')
  })

  it('tells the user when the venue cannot be found', async () => {
    renderVenueMap.mockResolvedValue({ found: false, map: {} })

    const wrapper = mount(EventDetailPage, { global: { stubs: { NuxtLink: true } } })
    await flushPromises()

    expect(wrapper.text()).toContain('Could not find this venue on the map.')
  })

  it('keeps the page working when the map cannot load', async () => {
    renderVenueMap.mockRejectedValue(new Error('Failed to load Leaflet'))
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})

    const wrapper = mount(EventDetailPage, { global: { stubs: { NuxtLink: true } } })
    await flushPromises()

    expect(wrapper.text()).toContain('The map is not available right now.')
    expect(wrapper.text()).toContain('Jazz Night')
    consoleError.mockRestore()
  })
})
