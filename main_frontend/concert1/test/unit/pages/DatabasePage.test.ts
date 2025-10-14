import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DatabasePage from '~/app/pages/DatabasePage.vue'

describe('DatabasePage', () => {
  it('should render the page title', () => {
    const wrapper = mount(DatabasePage)
    expect(wrapper.find('h1').text()).toBe('Database Page')
  })

  it('should render the placeholder text', () => {
    const wrapper = mount(DatabasePage)
    expect(wrapper.html()).toContain('This is a placeholder page')
  })

  it('should have proper styling classes', () => {
    const wrapper = mount(DatabasePage)
    expect(wrapper.find('section').classes()).toContain('p-6')
    expect(wrapper.find('h1').classes()).toContain('text-2xl')
  })

  it('should render without errors', () => {
    const wrapper = mount(DatabasePage)
    expect(wrapper.exists()).toBe(true)
  })
})
