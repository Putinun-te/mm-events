import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

const runtime = { backendBaseUrl: 'http://api.example.test' as string | undefined, fail: false }
vi.mock('nuxt/app', () => ({
  useRuntimeConfig: () => {
    if (runtime.fail) throw new Error('outside a Nuxt app')
    return { public: { backendBaseUrl: runtime.backendBaseUrl } }
  }
}))

import { useApi } from '~/composables/useApi'

describe('useApi', () => {
  const fetchMock = vi.fn()

  beforeEach(() => {
    runtime.backendBaseUrl = 'http://api.example.test'
    runtime.fail = false
    localStorage.clear()
    sessionStorage.clear()
    fetchMock.mockReset().mockResolvedValue({ ok: true })
    vi.stubGlobal('$fetch', fetchMock)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('calls the backend with JSON headers and returns the response', async () => {
    const { apiFetch } = useApi()

    const result = await apiFetch('/api/events', { method: 'POST', body: { title: 'x' } })

    expect(result).toEqual({ ok: true })
    expect(fetchMock).toHaveBeenCalledWith('http://api.example.test/api/events', {
      method: 'POST',
      body: { title: 'x' },
      headers: { 'Content-Type': 'application/json' }
    })
  })

  it('sends the stored token as a Bearer header', async () => {
    sessionStorage.setItem('jwt_token', 'session-token')
    const { apiFetch } = useApi()

    await apiFetch('/api/bookings/me', { headers: { 'X-Extra': '1' } })

    expect(fetchMock.mock.calls[0][1].headers).toEqual({
      'Content-Type': 'application/json',
      'X-Extra': '1',
      Authorization: 'Bearer session-token'
    })
  })

  it('prefers the remembered token in localStorage', async () => {
    localStorage.setItem('jwt_token', 'remembered-token')
    sessionStorage.setItem('jwt_token', 'session-token')
    const { apiFetch } = useApi()

    await apiFetch('/api/users/me')

    expect(fetchMock.mock.calls[0][1].headers.Authorization).toBe('Bearer remembered-token')
  })

  it('keeps a base path from the backend URL without doubling it', () => {
    runtime.backendBaseUrl = 'https://gateway.example.test/prod/'
    const { resolveApiUrl, backendUrl } = useApi()

    expect(backendUrl).toBe('https://gateway.example.test/prod')
    expect(resolveApiUrl('/api/events')).toBe('https://gateway.example.test/prod/api/events')
    expect(resolveApiUrl('api/events')).toBe('https://gateway.example.test/prod/api/events')
    expect(resolveApiUrl('/prod/api/events')).toBe('https://gateway.example.test/prod/api/events')
    expect(resolveApiUrl('')).toBe('https://gateway.example.test/prod')
  })

  it('uses absolute URLs as they are', () => {
    const { resolveApiUrl } = useApi()

    expect(resolveApiUrl('https://other.example.test/x')).toBe('https://other.example.test/x')
  })

  it('works with a backend URL without a path', () => {
    const { resolveApiUrl, backendUrl } = useApi()

    expect(backendUrl).toBe('http://api.example.test')
    expect(resolveApiUrl('/')).toBe('http://api.example.test/')
  })

  it('falls back to localhost:8080 when there is no runtime config', () => {
    runtime.fail = true
    const { backendUrl } = useApi()

    expect(backendUrl).toBe('http://localhost:8080')
  })

  it('falls back to localhost:8080 when the config has no backend URL', () => {
    runtime.backendBaseUrl = undefined
    const { backendUrl } = useApi()

    expect(backendUrl).toBe('http://localhost:8080')
  })
})
