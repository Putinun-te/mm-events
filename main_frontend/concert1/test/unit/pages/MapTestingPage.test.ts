import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import MapTestingPage from '~/app/pages/MapTestingPage.vue'

// Leaflet is normally loaded from a CDN; a global L makes loadLeaflet() use it directly.
function installFakeLeaflet() {
  const map = { setView: vi.fn(), getCenter: vi.fn(() => ({ lat: 1, lng: 2 })) }
  map.setView.mockReturnValue(map)
  const L = {
    map: vi.fn(() => map),
    tileLayer: vi.fn(() => ({ addTo: vi.fn() })),
    circleMarker: vi.fn(() => ({ addTo: vi.fn() }))
  }
  ;(globalThis as any).L = L
  return { L, map }
}

describe('MapTestingPage', () => {
  let fake: ReturnType<typeof installFakeLeaflet>

  beforeEach(() => {
    fake = installFakeLeaflet()
  })

  afterEach(() => {
    delete (globalThis as any).L
  })

  it('should render the page title', () => {
    const wrapper = mount(MapTestingPage)
    expect(wrapper.find('h1').text()).toBe('This is for testing map')
  })

  it('should render map container', () => {
    const wrapper = mount(MapTestingPage)
    expect(wrapper.find('#map').exists()).toBe(true)
  })

  it('should have proper map styling', () => {
    const wrapper = mount(MapTestingPage)
    const mapDiv = wrapper.find('#map')
    expect(mapDiv.attributes('style')).toContain('width: 100%')
    expect(mapDiv.attributes('style')).toContain('height: 500px')
  })

  it('should render without errors', () => {
    const wrapper = mount(MapTestingPage)
    expect(wrapper.exists()).toBe(true)
  })

  it('creates an OpenStreetMap map centred on Bangkok', async () => {
    const wrapper = mount(MapTestingPage)
    await flushPromises()

    expect(fake.L.map).toHaveBeenCalledWith(wrapper.find('#map').element)
    expect(fake.map.setView).toHaveBeenCalledWith([13.7563, 100.5018], 12)
    expect(fake.L.tileLayer.mock.calls[0][0]).toContain('tile.openstreetmap.org')
  })

  it('resets the view and adds a marker at the centre', async () => {
    const wrapper = mount(MapTestingPage)
    await flushPromises()
    const [reset, add] = wrapper.findAll('button')

    await add.trigger('click')
    await reset.trigger('click')

    expect(fake.L.circleMarker).toHaveBeenCalledWith({ lat: 1, lng: 2 }, { radius: 8 })
    expect(fake.map.setView).toHaveBeenCalledTimes(2)
  })
})
