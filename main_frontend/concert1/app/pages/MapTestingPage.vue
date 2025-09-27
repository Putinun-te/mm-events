<script setup lang="ts">
import { onMounted } from 'vue'

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const existing = document.querySelector(`script[src="${src}"]`)
    if (existing) {
      resolve()
      return
    }

    const script = document.createElement('script')
    script.src = src
    script.type = 'text/javascript'
    script.async = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error(`Failed to load script: ${src}`))
    document.head.appendChild(script)
  })
}

onMounted(async () => {
  await loadScript('https://api.longdo.com/map3/?key=REPLACE_WITH_MAP_API_KEY')
  const map = new longdo.Map({
    placeholder: document.getElementById('map')
  })
})
</script>

<template>
  <div>
    <h1>This is for testing map</h1>
    <div id="map" style="width: 100%; height: 500px;"></div>
  </div>
</template>
