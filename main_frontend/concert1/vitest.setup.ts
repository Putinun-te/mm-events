import { expect, afterEach, vi } from 'vitest'
import { cleanup } from '@testing-library/vue'
import '@testing-library/jest-dom'

// Cleanup after each test
afterEach(() => {
  cleanup()
})

// Mock Nuxt composables
vi.mock('#app', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    go: vi.fn(),
    back: vi.fn(),
    forward: vi.fn()
  }),
  useRoute: () => ({
    params: {},
    query: {},
    path: '/'
  }),
  navigateTo: vi.fn(),
  useState: vi.fn((key, init) => {
    const state = init ? init() : null
    return { value: state }
  }),
  useFetch: vi.fn(),
  useAsyncData: vi.fn(),
  useRuntimeConfig: () => ({
    public: {
      backendBaseUrl: ''
    }
  })
}))

// Mock NuxtLink component
vi.mock('nuxt/app', () => ({
  NuxtLink: {
    template: '<a><slot /></a>'
  },
  useRuntimeConfig: () => ({
    public: {
      backendBaseUrl: ''
    }
  })
}))

// Mock window.localStorage with actual storage functionality
class LocalStorageMock {
  private store: Record<string, string> = {}

  getItem(key: string): string | null {
    return this.store[key] || null
  }

  setItem(key: string, value: string): void {
    this.store[key] = String(value)
  }

  removeItem(key: string): void {
    delete this.store[key]
  }

  clear(): void {
    this.store = {}
  }

  get length(): number {
    return Object.keys(this.store).length
  }

  key(index: number): string | null {
    const keys = Object.keys(this.store)
    return keys[index] || null
  }
}

global.localStorage = new LocalStorageMock() as any
global.sessionStorage = new LocalStorageMock() as any

// Mock fetch
global.fetch = vi.fn()

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  error: vi.fn(),
  warn: vi.fn()
}
