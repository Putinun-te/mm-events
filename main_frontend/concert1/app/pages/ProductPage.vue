<script setup>
import { ref, onMounted } from 'vue'
import { useApi } from '~/composables/useApi'
import { useImage } from '~/composables/useImage'

const { apiFetch } = useApi()
const { getEventPhotoUrl } = useImage()
const events = ref([])
const loading = ref(true)

onMounted(async () => {
  try {
    const response = await apiFetch('/api/events')
    events.value = response.content || []
  } catch (error) {
    console.error('Failed to load events:', error)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="min-h-screen bg-gray-50 py-12">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-12">
        <h1 class="text-5xl font-bold text-gray-900 mb-4">All Events</h1>
        <p class="text-xl text-gray-600">Discover amazing concerts and events</p>
      </div>

      <div v-if="loading" class="text-center py-12">
        <p class="text-gray-500">Loading events...</p>
      </div>

      <div v-else-if="events.length === 0" class="text-center py-12">
        <p class="text-gray-500">No events available at the moment.</p>
        <NuxtLink to="/CreateEventPage" class="mt-4 inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
          Create First Event
        </NuxtLink>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <NuxtLink
          v-for="event in events"
          :key="event.id"
          :to="`/ProductPageDetail/${event.id}`"
          class="group bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-2xl transform hover:-translate-y-1 transition-all duration-300"
        >
          <div class="aspect-video overflow-hidden bg-gray-200">
            <img
              :src="getEventPhotoUrl(event.photoUrl)"
              :alt="event.title"
              class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
            />
          </div>
          <div class="p-6">
            <h3 class="text-xl font-bold text-gray-900 mb-2 line-clamp-2">{{ event.title }}</h3>
            <p class="text-gray-600 text-sm mb-4 line-clamp-2">{{ event.description }}</p>
            <div class="flex items-center justify-between">
              <span class="text-2xl font-bold text-green-600">${{ event.ticketPrice || 0 }}</span>
              <span class="text-sm text-gray-500">{{ event.location }}</span>
            </div>
          </div>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
