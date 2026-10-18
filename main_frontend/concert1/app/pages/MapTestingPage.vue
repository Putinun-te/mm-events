<template>
  <div class="map-testing-page">
    <section class="p-6">
      <h1 class="text-2xl font-bold mb-6">This is for testing map</h1>

      <div
        id="map"
        ref="mapContainer"
        class="isolate"
        style="width: 100%; height: 500px; border: 1px solid #ccc; border-radius: 8px;"
      ></div>

      <div class="mt-6">
        <h2 class="text-xl font-semibold mb-3">Map Controls</h2>
        <div class="flex gap-3">
          <button
            @click="resetMap"
            class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
          >
            Reset Map
          </button>
          <button
            @click="addMarker"
            class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors"
          >
            Add Marker
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { DEFAULT_CENTER, loadLeaflet } from '../composables/useVenueMap'

const mapContainer = ref<HTMLElement | null>(null)
const map = ref<any>(null)
let leaflet: any = null

onMounted(async () => {
  // Leaflet + OpenStreetMap, no API key needed
  try {
    leaflet = await loadLeaflet()
    map.value = leaflet.map(mapContainer.value).setView(DEFAULT_CENTER, 12)
    leaflet.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map.value)
  } catch (error) {
    console.error('Failed to initialize map:', error)
  }
})

const resetMap = () => {
  if (map.value) {
    map.value.setView(DEFAULT_CENTER, 12)
  }
}

const addMarker = () => {
  if (map.value && leaflet) {
    leaflet.circleMarker(map.value.getCenter(), { radius: 8 }).addTo(map.value)
  }
}
</script>
