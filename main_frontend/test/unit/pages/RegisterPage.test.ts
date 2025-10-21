import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createMemoryHistory } from 'vue-router'
import RegisterPage from '~/app/pages/RegisterPage.vue'

describe('RegisterPage.vue', () => {
  let router: any

  beforeEach(() => {
    router = createRouter({
      history: createMemoryHistory(),
      routes: [{ path: '/register', component: RegisterPage }]
    })
  })

  it('should render register page', () => {
    const wrapper = mount(RegisterPage, {
      global: { plugins: [router], stubs: { NuxtLink: true, Register: true } }
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('should contain register component', () => {
    const wrapper = mount(RegisterPage, {
      global: { plugins: [router], stubs: { NuxtLink: true, Register: true } }
    })
    expect(wrapper.html().length).toBeGreaterThan(0)
  })
})
