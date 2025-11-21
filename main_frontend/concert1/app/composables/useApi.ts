export const useApi = () => {
  const config = useRuntimeConfig()
  const baseURL = config.public.backendBaseUrl
  const backendUrl = baseURL

  const apiFetch = async (endpoint: string, options: any = {}) => {
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...options.headers
    }
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }

    const response = await fetch(`${baseURL}${endpoint}`, {
      ...options,
      headers
    })

    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`)
    }

    return response.json()
  }

  return { apiFetch, backendUrl }
}
