<template>
  <div class="map-testing-page">
    <section class="p-6">
      <h1 class="text-2xl font-bold mb-6">This is for testing map</h1>
      
      <div 
        id="map" 
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

const map = ref<any>(null)

onMounted(() => {
  // Initialize map if longdo is available (Longdo Map API)
  if (typeof window !== 'undefined' && (window as any).longdo) {
    try {
      map.value = new (window as any).longdo.Map({
        placeholder: document.getElementById('map')
      })
    } catch (error) {
      console.error('Failed to initialize map:', error)
    }
  }
})

const resetMap = () => {
  if (map.value) {
    map.value.location({ lon: 100.5, lat: 13.7 })
  }
}

const addMarker = () => {
  if (map.value) {
    console.log('Adding marker to map')
  }
}
</script>
