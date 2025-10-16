import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import MapTestingPage from '~/app/pages/MapTestingPage.vue'

describe('MapTestingPage', () => {
  beforeEach(() => {
    globalThis.longdo = {
      Map: vi.fn(() => ({
        Route: vi.fn(),
        location: vi.fn(),
        Event: vi.fn()
      }))
    }
  })

  afterEach(() => {
    // @ts-expect-error cleanup test shim
    delete globalThis.longdo
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
})
