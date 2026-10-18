// Venue map with Leaflet + OpenStreetMap. No API key is needed:
// - Leaflet is loaded from unpkg at a pinned version with Subresource Integrity,
// - map tiles come from tile.openstreetmap.org,
// - the venue text is turned into coordinates with Nominatim (OpenStreetMap search).

const LEAFLET_VERSION = '1.9.4'
const LEAFLET_JS = {
  src: `https://unpkg.com/leaflet@${LEAFLET_VERSION}/dist/leaflet.js`,
  integrity: 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo='
}
const LEAFLET_CSS = {
  href: `https://unpkg.com/leaflet@${LEAFLET_VERSION}/dist/leaflet.css`,
  integrity: 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY='
}
const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search'
const TILE_URL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
const ATTRIBUTION = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'

/** Bangkok, used when the venue cannot be found. */
export const DEFAULT_CENTER: [number, number] = [13.7563, 100.5018]

export interface Coordinates {
  lat: number
  lon: number
}

export interface VenueFields {
  location?: string | null
  address?: string | null
  city?: string | null
  country?: string | null
}

/** "Main Hall, 1 Road, Bangkok, Thailand" from whatever venue fields the event has. */
export function buildVenueQuery(event: VenueFields | null | undefined): string {
  if (!event) return ''
  const parts = [event.location, event.address, event.city, event.country]
    .map(part => (part ?? '').trim())
    .filter(part => part.length > 0)
  return [...new Set(parts)].join(', ')
}

/** Looks the venue up on Nominatim; null when it cannot be found or the lookup fails. */
export async function geocodeVenue(query: string, fetchImpl: typeof fetch = fetch): Promise<Coordinates | null> {
  if (!query.trim()) return null
  try {
    const url = `${NOMINATIM_URL}?format=json&limit=1&q=${encodeURIComponent(query)}`
    const response = await fetchImpl(url, { headers: { Accept: 'application/json' } })
    if (!response.ok) return null
    const results = await response.json()
    const first = Array.isArray(results) ? results[0] : null
    const lat = Number.parseFloat(first?.lat)
    const lon = Number.parseFloat(first?.lon)
    if (Number.isNaN(lat) || Number.isNaN(lon)) return null
    return { lat, lon }
  } catch {
    return null
  }
}

let leafletPromise: Promise<any> | null = null

/** Adds Leaflet's stylesheet and script once and resolves with the global `L`. */
export function loadLeaflet(doc: Document = document): Promise<any> {
  const win = doc.defaultView as any
  if (win?.L) return Promise.resolve(win.L)
  if (leafletPromise) return leafletPromise

  if (!doc.querySelector(`link[href="${LEAFLET_CSS.href}"]`)) {
    const link = doc.createElement('link')
    link.rel = 'stylesheet'
    link.href = LEAFLET_CSS.href
    link.integrity = LEAFLET_CSS.integrity
    link.crossOrigin = 'anonymous'
    doc.head.appendChild(link)
  }

  leafletPromise = new Promise((resolve, reject) => {
    const script = doc.createElement('script')
    script.src = LEAFLET_JS.src
    script.integrity = LEAFLET_JS.integrity
    script.crossOrigin = 'anonymous'
    script.async = true
    script.onload = () => resolve(win?.L)
    script.onerror = () => {
      leafletPromise = null
      reject(new Error('Failed to load Leaflet'))
    }
    doc.head.appendChild(script)
  })
  return leafletPromise
}

/** Test hook: forget a previous load attempt. */
export function resetLeafletLoader() {
  leafletPromise = null
}

export interface VenueMapResult {
  found: boolean
  map: any
}

/**
 * Draws an OpenStreetMap map into `container` and pins the venue if it can be found.
 * The popup shows the venue text as plain text (it is user input).
 */
export async function renderVenueMap(
  container: HTMLElement,
  query: string,
  deps: { load?: () => Promise<any>, geocode?: (q: string) => Promise<Coordinates | null> } = {}
): Promise<VenueMapResult> {
  const L = await (deps.load ?? (() => loadLeaflet()))()
  const map = L.map(container).setView(DEFAULT_CENTER, 11)
  L.tileLayer(TILE_URL, { maxZoom: 19, attribution: ATTRIBUTION }).addTo(map)

  const coordinates = await (deps.geocode ?? geocodeVenue)(query)
  if (!coordinates) return { found: false, map }

  map.setView([coordinates.lat, coordinates.lon], 15)
  const label = container.ownerDocument.createElement('span')
  label.textContent = query
  L.circleMarker([coordinates.lat, coordinates.lon], { radius: 9, color: '#7c3aed', fillOpacity: 0.8 })
    .addTo(map)
    .bindPopup(label)
  return { found: true, map }
}
