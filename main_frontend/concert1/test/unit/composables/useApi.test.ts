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

  describe('refresh on 401', () => {
    const unauthorized = () => Object.assign(new Error('Unauthorized'), { status: 401 })

    it('refreshes once and retries the request with the new token', async () => {
      sessionStorage.setItem('jwt_token', 'expired-access')
      sessionStorage.setItem('refresh_token', 'refresh-1')
      fetchMock
        .mockRejectedValueOnce(unauthorized())
        .mockResolvedValueOnce({ token: 'new-access', refreshToken: 'refresh-2' })
        .mockResolvedValueOnce({ id: 7 })
      const { apiFetch } = useApi()

      const result = await apiFetch('/api/bookings/me')

      expect(result).toEqual({ id: 7 })
      expect(fetchMock.mock.calls[1][0]).toBe('http://api.example.test/api/auth/refresh')
      expect(fetchMock.mock.calls[1][1].body).toEqual({ refreshToken: 'refresh-1' })
      expect(fetchMock.mock.calls[2][1].headers.Authorization).toBe('Bearer new-access')
      expect(sessionStorage.getItem('jwt_token')).toBe('new-access')
      expect(sessionStorage.getItem('refresh_token')).toBe('refresh-2')
    })

    it('keeps remembered tokens in localStorage', async () => {
      localStorage.setItem('jwt_token', 'expired-access')
      localStorage.setItem('refresh_token', 'refresh-1')
      fetchMock
        .mockRejectedValueOnce(unauthorized())
        .mockResolvedValueOnce({ token: 'new-access', refreshToken: 'refresh-2' })
        .mockResolvedValueOnce({})
      const { apiFetch } = useApi()

      await apiFetch('/api/users/me')

      expect(localStorage.getItem('refresh_token')).toBe('refresh-2')
      expect(sessionStorage.getItem('refresh_token')).toBeNull()
    })

    it('shares one refresh between requests that fail together', async () => {
      sessionStorage.setItem('refresh_token', 'refresh-1')
      let resolveRefresh: (value: unknown) => void = () => {}
      fetchMock.mockImplementation((url: string) => {
        if (url.endsWith('/api/auth/refresh')) {
          return new Promise(resolve => { resolveRefresh = resolve })
        }
        return sessionStorage.getItem('jwt_token') === 'new-access'
          ? Promise.resolve({ ok: url })
          : Promise.reject(unauthorized())
      })
      const { apiFetch } = useApi()

      const both = Promise.all([apiFetch('/api/a'), apiFetch('/api/b')])
      await new Promise(resolve => setTimeout(resolve, 0))
      resolveRefresh({ token: 'new-access', refreshToken: 'refresh-2' })

      await expect(both).resolves.toHaveLength(2)
      const refreshCalls = fetchMock.mock.calls.filter(([url]) => String(url).endsWith('/api/auth/refresh'))
      expect(refreshCalls).toHaveLength(1)
    })

    it('rethrows the 401 when there is no refresh token', async () => {
      fetchMock.mockRejectedValueOnce(unauthorized())
      const { apiFetch } = useApi()

      await expect(apiFetch('/api/users/me')).rejects.toMatchObject({ status: 401 })
      expect(fetchMock).toHaveBeenCalledTimes(1)
    })

    it('rethrows the 401 when the refresh is refused', async () => {
      sessionStorage.setItem('refresh_token', 'revoked')
      fetchMock
        .mockRejectedValueOnce(unauthorized())
        .mockRejectedValueOnce(unauthorized())
      const { apiFetch } = useApi()

      await expect(apiFetch('/api/users/me')).rejects.toMatchObject({ status: 401 })
      expect(fetchMock).toHaveBeenCalledTimes(2)
      expect(sessionStorage.getItem('refresh_token')).toBe('revoked')
    })

    it('rethrows when the refresh answer has no tokens', async () => {
      sessionStorage.setItem('refresh_token', 'refresh-1')
      fetchMock
        .mockRejectedValueOnce(unauthorized())
        .mockResolvedValueOnce({ message: 'odd' })
      const { apiFetch } = useApi()

      await expect(apiFetch('/api/users/me')).rejects.toMatchObject({ status: 401 })
    })

    it('does not refresh for other errors or for the auth endpoints', async () => {
      sessionStorage.setItem('refresh_token', 'refresh-1')
      fetchMock
        .mockRejectedValueOnce(Object.assign(new Error('Forbidden'), { status: 403 }))
        .mockRejectedValueOnce(Object.assign(new Error('Unauthorized'), { statusCode: 401 }))
      const { apiFetch } = useApi()

      await expect(apiFetch('/api/events/1')).rejects.toMatchObject({ status: 403 })
      await expect(apiFetch('/api/auth/login', { method: 'POST' })).rejects.toMatchObject({ statusCode: 401 })
      expect(fetchMock).toHaveBeenCalledTimes(2)
    })
  })

  describe('authFetch', () => {
    const rawFetch = vi.fn()
    const response = (status: number) => ({ status, ok: status >= 200 && status < 300 })

    beforeEach(() => {
      rawFetch.mockReset().mockResolvedValue(response(200))
      vi.stubGlobal('fetch', rawFetch)
    })

    it('sends the stored token without adding a JSON content type', async () => {
      localStorage.setItem('jwt_token', 'remembered-token')
      const body = new FormData()
      body.append('file', new Blob(['x']), 'photo.jpg')
      const { authFetch } = useApi()

      const result = await authFetch('/api/upload/event-photo', { method: 'POST', body })

      expect(result).toEqual(response(200))
      expect(rawFetch).toHaveBeenCalledWith('http://api.example.test/api/upload/event-photo', {
        method: 'POST',
        body,
        headers: { Authorization: 'Bearer remembered-token' }
      })
      expect(fetchMock).not.toHaveBeenCalled()
    })

    it('renews the token on a 401 and retries a DELETE once', async () => {
      sessionStorage.setItem('jwt_token', 'expired-access')
      sessionStorage.setItem('refresh_token', 'refresh-1')
      rawFetch.mockResolvedValueOnce(response(401)).mockResolvedValueOnce(response(204))
      fetchMock.mockResolvedValueOnce({ token: 'new-access', refreshToken: 'refresh-2' })
      const { authFetch } = useApi()

      const result = await authFetch('/api/bookings/5', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' }
      })

      expect(result.status).toBe(204)
      expect(fetchMock).toHaveBeenCalledTimes(1)
      expect(fetchMock.mock.calls[0][0]).toBe('http://api.example.test/api/auth/refresh')
      expect(fetchMock.mock.calls[0][1].body).toEqual({ refreshToken: 'refresh-1' })
      expect(rawFetch).toHaveBeenCalledTimes(2)
      expect(rawFetch.mock.calls[0][1].headers.Authorization).toBe('Bearer expired-access')
      expect(rawFetch.mock.calls[1]).toEqual(['http://api.example.test/api/bookings/5', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer new-access' }
      }])
      expect(sessionStorage.getItem('refresh_token')).toBe('refresh-2')
    })

    it('renews the token on a 401 and resends the same multipart body', async () => {
      localStorage.setItem('jwt_token', 'expired-access')
      localStorage.setItem('refresh_token', 'refresh-1')
      rawFetch.mockResolvedValueOnce(response(401)).mockResolvedValueOnce(response(200))
      fetchMock.mockResolvedValueOnce({ token: 'new-access', refreshToken: 'refresh-2' })
      const body = new FormData()
      body.append('file', new Blob(['x']), 'photo.jpg')
      const { authFetch } = useApi()

      const result = await authFetch('/api/upload/event-photo', { method: 'POST', body })

      expect(result.status).toBe(200)
      expect(rawFetch).toHaveBeenCalledTimes(2)
      const [, retry] = rawFetch.mock.calls[1]
      expect(retry.body).toBe(body)
      expect(retry.headers).toEqual({ Authorization: 'Bearer new-access' })
      expect(localStorage.getItem('jwt_token')).toBe('new-access')
    })

    it('returns the 401 when the refresh is refused', async () => {
      sessionStorage.setItem('jwt_token', 'expired-access')
      sessionStorage.setItem('refresh_token', 'revoked')
      rawFetch.mockResolvedValueOnce(response(401))
      fetchMock.mockRejectedValueOnce(Object.assign(new Error('Unauthorized'), { status: 401 }))
      const { authFetch } = useApi()

      const result = await authFetch('/api/bookings/5', { method: 'DELETE' })

      expect(result.status).toBe(401)
      expect(rawFetch).toHaveBeenCalledTimes(1)
    })

    it('returns the 401 without a refresh when there is no refresh token', async () => {
      sessionStorage.setItem('jwt_token', 'expired-access')
      rawFetch.mockResolvedValueOnce(response(401))
      const { authFetch } = useApi()

      const result = await authFetch('/api/bookings/5', { method: 'DELETE' })

      expect(result.status).toBe(401)
      expect(fetchMock).not.toHaveBeenCalled()
      expect(rawFetch).toHaveBeenCalledTimes(1)
    })

    it('does not refresh for other statuses or for the auth endpoints', async () => {
      sessionStorage.setItem('refresh_token', 'refresh-1')
      rawFetch.mockResolvedValueOnce(response(403)).mockResolvedValueOnce(response(401))
      const { authFetch } = useApi()

      expect((await authFetch('/api/bookings/5', { method: 'DELETE' })).status).toBe(403)
      expect((await authFetch('/api/auth/logout', { method: 'POST' })).status).toBe(401)
      expect(fetchMock).not.toHaveBeenCalled()
      expect(rawFetch).toHaveBeenCalledTimes(2)
    })

    it('shares one refresh with apiFetch when both fail together', async () => {
      sessionStorage.setItem('refresh_token', 'refresh-1')
      let resolveRefresh: (value: unknown) => void = () => {}
      fetchMock.mockImplementation((url: string) => {
        if (url.endsWith('/api/auth/refresh')) {
          return new Promise(resolve => { resolveRefresh = resolve })
        }
        return sessionStorage.getItem('jwt_token') === 'new-access'
          ? Promise.resolve({ ok: url })
          : Promise.reject(Object.assign(new Error('Unauthorized'), { status: 401 }))
      })
      rawFetch.mockImplementation(() => Promise.resolve(
        response(sessionStorage.getItem('jwt_token') === 'new-access' ? 204 : 401)
      ))
      const { apiFetch, authFetch } = useApi()

      const both = Promise.all([apiFetch('/api/bookings/me'), authFetch('/api/bookings/5', { method: 'DELETE' })])
      await new Promise(resolve => setTimeout(resolve, 0))
      resolveRefresh({ token: 'new-access', refreshToken: 'refresh-2' })

      const [, deleted] = await both
      expect(deleted.status).toBe(204)
      const refreshCalls = fetchMock.mock.calls.filter(([url]) => String(url).endsWith('/api/auth/refresh'))
      expect(refreshCalls).toHaveLength(1)
    })
  })
})
