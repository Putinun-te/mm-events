import type { FetchOptions } from 'ofetch'
import { useRuntimeConfig } from 'nuxt/app'

const trimTrailingSlash = (value: string): string => value.replace(/\/+$/, '')
const trimLeadingSlash = (value: string): string => value.replace(/^\/+/, '')

const joinPaths = (basePath: string, relativePath: string): string => {
  const cleanedBase = trimTrailingSlash(basePath || '')
  const cleanedRelative = trimLeadingSlash(relativePath || '')

  if (!cleanedBase && !cleanedRelative) {
    return '/'
  }

  if (!cleanedBase) {
    return `/${cleanedRelative}`
  }

  if (!cleanedRelative) {
    return cleanedBase.startsWith('/') ? cleanedBase : `/${cleanedBase}`
  }

  return `${cleanedBase.startsWith('/') ? cleanedBase : `/${cleanedBase}`}/${cleanedRelative}`
}

const resolveRuntimeConfig = () => {
  try {
    if (typeof useRuntimeConfig === 'function') {
      const config = useRuntimeConfig()
      if (config && config.public) {
        return config
      }
    }
  } catch {
    // no-op: fall back to environment based defaults below
  }

  return {
    public: {
      backendBaseUrl:
        process.env.API_GATEWAY_URL ||
        process.env.BACKEND_BASE_URL ||
        'http://localhost:8080'
    }
  }
}

// Requests that must not trigger a token refresh (they are how a session starts or ends).
const NO_REFRESH = ['/api/auth/login', '/api/auth/register', '/api/auth/refresh', '/api/auth/logout']
const isRefreshable = (fullUrl: string): boolean => !NO_REFRESH.some(path => fullUrl.includes(path))

// One refresh at a time: requests that fail together wait for the same refresh.
let refreshInFlight: Promise<boolean> | null = null

const statusOf = (error: any): number | undefined =>
  error?.status ?? error?.statusCode ?? error?.response?.status

// The refresh token is stored next to the access token (localStorage with "Remember me").
const tokenStorage = (): Storage | null => {
  if (localStorage.getItem('refresh_token')) return localStorage
  if (sessionStorage.getItem('refresh_token')) return sessionStorage
  return null
}

export const useApi = () => {
  const config = resolveRuntimeConfig()
  const rawBaseUrl = config.public.backendBaseUrl ?? 'http://localhost:8080'

  let origin = rawBaseUrl
  let basePath = ''

  try {
    const parsed = new URL(rawBaseUrl.endsWith('/') ? rawBaseUrl : `${rawBaseUrl}/`)
    origin = `${parsed.protocol}//${parsed.host}`
    basePath = trimTrailingSlash(parsed.pathname)
  } catch {
    origin = trimTrailingSlash(rawBaseUrl)
    basePath = ''
  }

  const parseAbsoluteUrl = (maybeUrl: string): string | null => {
    try {
      return new URL(maybeUrl).toString()
    } catch {
      return null
    }
  }

  const resolveApiUrl = (url: string): string => {
    if (!url) {
      return origin + (basePath || '')
    }

    const absoluteCandidate = parseAbsoluteUrl(url)
    if (absoluteCandidate) {
      return absoluteCandidate
    }

    const normalizedInput = url.startsWith('/') ? url : `/${url}`

    let relativePath = normalizedInput
    if (basePath && normalizedInput.startsWith(basePath)) {
      relativePath = normalizedInput.slice(basePath.length) || '/'
    }

    const finalPath = joinPaths(basePath, relativePath)
    return `${origin}${finalPath}`
  }

  // Trades the stored refresh token for a new access + refresh token; false if that is not possible.
  const refreshSession = (): Promise<boolean> => {
    if (!refreshInFlight) {
      refreshInFlight = (async () => {
        const storage = tokenStorage()
        if (!storage) return false
        try {
          const res: any = await $fetch(resolveApiUrl('/api/auth/refresh'), {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: { refreshToken: storage.getItem('refresh_token') }
          } as any)
          if (!res?.token || !res?.refreshToken) return false
          storage.setItem('jwt_token', res.token)
          storage.setItem('refresh_token', res.refreshToken)
          return true
        } catch {
          return false
        }
      })().finally(() => {
        refreshInFlight = null
      })
    }
    return refreshInFlight
  }

  const send = <T>(fullUrl: string, options: FetchOptions): Promise<T> => {
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {})
    }
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }
    
    const fetchOptions: FetchOptions = {
      ...options,
      headers
    }
    
    return $fetch(fullUrl, fetchOptions as any) as Promise<T>
  }

  // Access tokens are short-lived: on a 401 the request is retried once after a refresh.
  const apiFetch = async <T = unknown>(url: string, options: FetchOptions = {}): Promise<T> => {
    const fullUrl = resolveApiUrl(url)
    try {
      return await send<T>(fullUrl, options)
    } catch (error) {
      const refreshable = statusOf(error) === 401 && isRefreshable(fullUrl)
      if (!refreshable || !(await refreshSession())) throw error
      return await send<T>(fullUrl, options)
    }
  }

  // Plain fetch with the stored token, for requests apiFetch cannot send: a FormData body needs
  // the browser to set its own multipart Content-Type. Resolves to the Response like fetch does;
  // a 401 is retried once after a refresh, and if that is not possible the 401 is returned.
  const authFetch = async (
    url: string,
    init: Omit<RequestInit, 'headers'> & { headers?: Record<string, string> } = {}
  ): Promise<Response> => {
    const fullUrl = resolveApiUrl(url)
    const sendRaw = () => {
      const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
      const headers: Record<string, string> = { ...init.headers }
      if (token) {
        headers['Authorization'] = `Bearer ${token}`
      }
      return fetch(fullUrl, { ...init, headers })
    }

    const response = await sendRaw()
    if (response.status !== 401 || !isRefreshable(fullUrl) || !(await refreshSession())) return response
    return sendRaw()
  }

  return {
    apiFetch,
    authFetch,
    backendUrl: origin + (basePath || ''),
    resolveApiUrl
  }
}
