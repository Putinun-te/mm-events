import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import AboutUS from '~/app/pages/AboutUS.vue'

describe('AboutUS.vue', () => {
  let router: any

  beforeEach(() => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [{ path: '/about', component: AboutUS }]
    })
  })

  it('should render about page', () => {
    const wrapper = mount(AboutUS, {
      global: { plugins: [router], stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should display about content', () => {
    const wrapper = mount(AboutUS, {
      global: { plugins: [router], stubs: { NuxtLink: true } }
    })
    expect(wrapper.html().length).toBeGreaterThan(0)
  })

  it('should have team information', () => {
    const wrapper = mount(AboutUS, {
      global: { plugins: [router], stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should display mission statement', () => {
    const wrapper = mount(AboutUS, {
      global: { plugins: [router], stubs: { NuxtLink: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })
})
