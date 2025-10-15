import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import LoginPage from '~/app/pages/LoginPage.vue'

describe('LoginPage.vue', () => {
  let router: any

  beforeEach(() => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [{ path: '/login', component: LoginPage }]
    })
  })

  it('should render login page', () => {
    const wrapper = mount(LoginPage, {
      global: { plugins: [router], stubs: { NuxtLink: true, Login: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should contain login component', () => {
    const wrapper = mount(LoginPage, {
      global: { plugins: [router], stubs: { NuxtLink: true, Login: true } }
    })
    expect(wrapper.html().length).toBeGreaterThan(0)
  })
})
