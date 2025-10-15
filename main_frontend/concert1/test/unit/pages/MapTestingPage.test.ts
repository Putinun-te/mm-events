import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import MapTestingPage from '~/app/pages/MapTestingPage.vue'

describe('MapTestingPage', () => {
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
