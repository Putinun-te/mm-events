<template>
  <div class="animate-pulse">
    <div class="bg-gray-200 rounded-xl h-64 mb-4"></div>
    <div class="space-y-3">
      <div class="h-6 bg-gray-200 rounded w-3/4"></div>
      <div class="h-4 bg-gray-200 rounded w-full"></div>
      <div class="h-4 bg-gray-200 rounded w-5/6"></div>
      <div class="flex gap-2 mt-4">
        <div class="h-8 bg-gray-200 rounded w-20"></div>
        <div class="h-8 bg-gray-200 rounded w-24"></div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Event card skeleton loader
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>
