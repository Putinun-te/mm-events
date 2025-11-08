<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuth } from '~/composables/useAuth'

const { loadFromStorage } = useAuth()

onMounted(() => {
  loadFromStorage()
})
</script>

<template>
  <div>
    <NavBar />
    <div class="mx-auto max-w-5xl pt-16 px-2 pb-2">
      <slot />
    </div>
    <Toasts />
  </div>
</template>