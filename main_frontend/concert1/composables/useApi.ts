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

  const apiFetch = async <T = unknown>(url: string, options: FetchOptions = {}): Promise<T> => {
    const fullUrl = resolveApiUrl(url)
    const headers = options.headers as Record<string, string> | undefined
    const fetchOptions: FetchOptions = {
      ...options,
      headers: headers ? { ...headers } : undefined
    }
    return $fetch(fullUrl, fetchOptions as any) as Promise<T>
  }

  return {
    apiFetch,
    backendUrl: origin + (basePath || ''),
    resolveApiUrl
  }
}
