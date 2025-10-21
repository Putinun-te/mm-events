<template>
  <div class="text-center py-16 px-4">
    <div class="max-w-md mx-auto">
      <!-- Icon or Illustration -->
      <div class="mb-6">
        <div v-if="type === 'no-events'" class="text-8xl">🎭</div>
        <div v-else-if="type === 'no-bookings'" class="text-8xl">🎫</div>
        <div v-else-if="type === 'no-search-results'" class="text-8xl">🔍</div>
        <div v-else class="text-8xl">📭</div>
      </div>

      <!-- Title -->
      <h3 class="text-2xl font-bold text-gray-900 mb-3">
        {{ title }}
      </h3>

      <!-- Description -->
      <p class="text-gray-600 mb-8">
        {{ description }}
      </p>

      <!-- Action Button -->
      <NuxtLink
        v-if="actionLink"
        :to="actionLink"
        class="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-semibold rounded-lg hover:shadow-lg transform hover:scale-105 transition-all duration-200"
      >
        <span>{{ actionText }}</span>
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
        </svg>
      </NuxtLink>

      <!-- Secondary Action -->
      <button
        v-if="secondaryAction"
        @click="$emit('secondary-action')"
        class="ml-4 inline-flex items-center gap-2 px-6 py-3 border-2 border-gray-300 text-gray-700 font-semibold rounded-lg hover:bg-gray-50 transition-all duration-200"
      >
        {{ secondaryText }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  type?: 'no-events' | 'no-bookings' | 'no-search-results' | 'default'
  title: string
  description: string
  actionLink?: string
  actionText?: string
  secondaryAction?: boolean
  secondaryText?: string
}>()

defineEmits<{
  'secondary-action': []
}>()
</script>
