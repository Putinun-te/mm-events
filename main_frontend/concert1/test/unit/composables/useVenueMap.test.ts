import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import {
  DEFAULT_CENTER,
  buildVenueQuery,
  geocodeVenue,
  loadLeaflet,
  renderVenueMap,
  resetLeafletLoader
} from '~/app/composables/useVenueMap'

function fakeLeaflet() {
  const map = { setView: vi.fn(), getCenter: vi.fn() }
  map.setView.mockReturnValue(map)
  const layer = { addTo: vi.fn() }
  const marker = { addTo: vi.fn(), bindPopup: vi.fn() }
  marker.addTo.mockReturnValue(marker)
  return {
    map,
    layer,
    marker,
    L: {
      map: vi.fn(() => map),
      tileLayer: vi.fn(() => layer),
      circleMarker: vi.fn(() => marker)
    }
  }
}

function jsonResponse(body: unknown, ok = true) {
  return { ok, json: () => Promise.resolve(body) } as unknown as Response
}

describe('buildVenueQuery', () => {
  it('joins the non-empty venue fields once each', () => {
    expect(buildVenueQuery({ location: ' Main Hall ', address: '', city: 'Bangkok', country: 'Thailand' }))
      .toBe('Main Hall, Bangkok, Thailand')
    expect(buildVenueQuery({ location: 'Bangkok', city: 'Bangkok' })).toBe('Bangkok')
  })

  it('returns an empty string without venue data', () => {
    expect(buildVenueQuery(null)).toBe('')
    expect(buildVenueQuery({ location: null, city: '  ' })).toBe('')
  })
})

describe('geocodeVenue', () => {
  it('returns the first Nominatim result as numbers and encodes the query', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(jsonResponse([{ lat: '13.7465', lon: '100.5348' }]))

    await expect(geocodeVenue('Siam Paragon, Bangkok', fetchImpl)).resolves.toEqual({ lat: 13.7465, lon: 100.5348 })
    expect(fetchImpl.mock.calls[0][0]).toBe(
      'https://nominatim.openstreetmap.org/search?format=json&limit=1&q=Siam%20Paragon%2C%20Bangkok'
    )
  })

  it('returns null for an empty query without calling the service', async () => {
    const fetchImpl = vi.fn()

    await expect(geocodeVenue('   ', fetchImpl)).resolves.toBeNull()
    expect(fetchImpl).not.toHaveBeenCalled()
  })

  it('returns null when nothing is found or the lookup fails', async () => {
    await expect(geocodeVenue('x', vi.fn().mockResolvedValue(jsonResponse([])))).resolves.toBeNull()
    await expect(geocodeVenue('x', vi.fn().mockResolvedValue(jsonResponse([{ lat: 'abc', lon: '1' }])))).resolves.toBeNull()
    await expect(geocodeVenue('x', vi.fn().mockResolvedValue(jsonResponse({}, false))))
      .resolves.toBeNull()
    await expect(geocodeVenue('x', vi.fn().mockRejectedValue(new Error('offline')))).resolves.toBeNull()
  })
})

describe('loadLeaflet', () => {
  beforeEach(() => {
    resetLeafletLoader()
    delete (window as any).L
    document.head.innerHTML = ''
  })

  afterEach(() => {
    delete (window as any).L
  })

  it('reuses an already loaded Leaflet', async () => {
    const L = { map: vi.fn() }
    ;(window as any).L = L

    await expect(loadLeaflet()).resolves.toBe(L)
    expect(document.head.querySelectorAll('script')).toHaveLength(0)
  })

  it('adds a pinned script and stylesheet with integrity hashes, once', async () => {
    const first = loadLeaflet()
    const second = loadLeaflet()
    const script = document.head.querySelector('script') as HTMLScriptElement
    const link = document.head.querySelector('link') as HTMLLinkElement

    expect(document.head.querySelectorAll('script')).toHaveLength(1)
    expect(script.src).toBe('https://unpkg.com/leaflet@1.9.4/dist/leaflet.js')
    expect(script.integrity).toMatch(/^sha256-/)
    expect(script.crossOrigin).toBe('anonymous')
    expect(link.href).toBe('https://unpkg.com/leaflet@1.9.4/dist/leaflet.css')
    expect(link.integrity).toMatch(/^sha256-/)

    const L = { map: vi.fn() }
    ;(window as any).L = L
    script.onload?.(new Event('load'))
    await expect(first).resolves.toBe(L)
    await expect(second).resolves.toBe(L)
  })

  it('rejects when the script cannot be loaded and allows a retry', async () => {
    const attempt = loadLeaflet()
    const script = document.head.querySelector('script') as HTMLScriptElement
    script.onerror?.(new Event('error'))

    await expect(attempt).rejects.toThrow('Failed to load Leaflet')
    loadLeaflet()
    expect(document.head.querySelectorAll('script')).toHaveLength(2)
  })
})

describe('renderVenueMap', () => {
  it('pins the venue when it is found and shows the name as plain text', async () => {
    const fake = fakeLeaflet()
    const container = document.createElement('div')
    const query = '<img src=x onerror=alert(1)> Hall, Bangkok'

    const result = await renderVenueMap(container, query, {
      load: () => Promise.resolve(fake.L),
      geocode: () => Promise.resolve({ lat: 13.75, lon: 100.5 })
    })

    expect(result.found).toBe(true)
    expect(fake.L.map).toHaveBeenCalledWith(container)
    expect(fake.L.tileLayer.mock.calls[0][1].attribution).toContain('OpenStreetMap')
    expect(fake.map.setView).toHaveBeenLastCalledWith([13.75, 100.5], 15)
    expect(fake.L.circleMarker).toHaveBeenCalledWith([13.75, 100.5], expect.any(Object))
    const popup = fake.marker.bindPopup.mock.calls[0][0] as HTMLElement
    expect(popup.textContent).toBe(query)
    expect(popup.querySelector('img')).toBeNull()
  })

  it('keeps the default view without a pin when the venue is not found', async () => {
    const fake = fakeLeaflet()

    const result = await renderVenueMap(document.createElement('div'), 'Nowhere', {
      load: () => Promise.resolve(fake.L),
      geocode: () => Promise.resolve(null)
    })

    expect(result.found).toBe(false)
    expect(fake.map.setView).toHaveBeenCalledTimes(1)
    expect(fake.map.setView).toHaveBeenCalledWith(DEFAULT_CENTER, 11)
    expect(fake.L.circleMarker).not.toHaveBeenCalled()
  })
})
