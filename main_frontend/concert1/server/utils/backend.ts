export const buildBackendUrl = (base: string, path: string): string => {
  if (!path) {
    return base
  }

  if (path.startsWith('http')) {
    return path
  }

  const normalizedPath = path.startsWith('/') ? path : `/${path}`
  const normalizedBase = base || 'http://localhost:8080'

  try {
    const baseUrl = normalizedBase.endsWith('/') ? normalizedBase : `${normalizedBase}/`
    return new URL(normalizedPath, baseUrl).toString()
  } catch {
    const trimmedBase = normalizedBase.replace(/\/+$/, '')
    return `${trimmedBase}${normalizedPath}`
  }
}
