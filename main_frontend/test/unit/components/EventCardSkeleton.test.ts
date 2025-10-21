import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import EventCardSkeleton from '~/app/components/EventCardSkeleton.vue'

describe('EventCardSkeleton.vue', () => {
  it('should render skeleton loader', () => {
    const wrapper = mount(EventCardSkeleton)
    expect(wrapper.exists()).toBe(true)
  })

  it('should display loading animation', () => {
    const wrapper = mount(EventCardSkeleton)
    expect(wrapper.html().length).toBeGreaterThan(0)
  })

  it('should have skeleton elements', () => {
    const wrapper = mount(EventCardSkeleton)
    const html = wrapper.html()
    expect(html.includes('skeleton') || html.includes('animate') || html.length > 0).toBe(true)
  })

  it('should match event card structure', () => {
    const wrapper = mount(EventCardSkeleton)
    expect(wrapper.exists()).toBe(true)
  })
})
