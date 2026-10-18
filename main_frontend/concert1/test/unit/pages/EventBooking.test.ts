import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'

// Booking from the event detail page (app/pages/product-page-detail/[id].vue).
const { apiFetch, toastError, toastSuccess } = vi.hoisted(() => {
  const g = globalThis as any
  g.definePageMeta = () => {}
  g.useRoute = () => ({ params: { id: '7' }, query: {}, path: '/product-page-detail/7' })
  return { apiFetch: vi.fn(), toastError: vi.fn(), toastSuccess: vi.fn() }
})

vi.mock('~/composables/useApi', () => ({ useApi: () => ({ apiFetch }) }))
vi.mock('~/app/composables/useVenueMap', async () => {
  const actual = await vi.importActual<any>('~/app/composables/useVenueMap')
  return { ...actual, renderVenueMap: vi.fn().mockResolvedValue({ found: true, map: {} }) }
})
vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({ loadFromStorage: vi.fn(), isLoggedIn: { value: true }, logout: vi.fn() })
}))
vi.mock('~/composables/useToast', () => ({
  useToast: () => ({ success: toastSuccess, error: toastError, info: vi.fn(), warning: vi.fn() })
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
  ticketPrice: 25,
  personLimit: 100,
  participantsCount: 0,
  startDate: '2030-05-01T19:00:00',
  endDate: '2030-05-01T22:00:00'
}

async function clickBook() {
  const wrapper = mount(EventDetailPage, { global: { stubs: { NuxtLink: true } } })
  await flushPromises()
  const button = wrapper.findAll('button').find(b => b.text().includes('Book'))
  expect(button).toBeDefined()
  await button!.trigger('click')
  await flushPromises()
  return wrapper
}

describe('event detail booking', () => {
  beforeEach(() => {
    apiFetch.mockReset()
    toastError.mockReset()
    toastSuccess.mockReset()
    localStorage.setItem('jwt_token', 'token')
    window.history.replaceState({ event }, '')
  })

  it('sends only the event id and quantity; the server sets price and details', async () => {
    apiFetch.mockResolvedValue({})

    await clickBook()

    const [url, options] = apiFetch.mock.calls[0]
    expect(url).toBe('/api/bookings')
    expect(JSON.parse(options.body)).toEqual({ eventId: '7', quantity: 1 })
    expect(toastSuccess).toHaveBeenCalled()
  })

  it('shows the server message when seats ran out (409)', async () => {
    apiFetch.mockRejectedValueOnce({ status: 409, data: { status: 409, error: 'Only 2 seat(s) left' } })

    await clickBook()

    expect(toastError).toHaveBeenCalledWith('Only 2 seat(s) left', 'Booking Failed')
  })

  it('falls back to a generic message when the server gives none', async () => {
    apiFetch.mockRejectedValueOnce(new Error('network down'))

    await clickBook()

    expect(toastError).toHaveBeenCalledWith('Failed to create booking', 'Booking Failed')
  })
})
