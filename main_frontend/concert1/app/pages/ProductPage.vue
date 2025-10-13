<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import ProductTag from '~/components/ProductTag.vue'

type EventItem = any

const events = ref<EventItem[]>([])
const loading = ref(false)
const message = ref('')

const page = ref(0)
const size = ref(12)

// Filters
const searchQuery = ref('')
const selectedCategory = ref('')
const selectedDate = ref('')

const categories = ['All', 'Music', 'Sports', 'Tech', 'Art', 'Food', 'Business', 'Other']

const hasEvents = computed(() => events.value.length > 0)

const filteredEvents = computed(() => {
  let result = events.value

  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(e => 
      (e.title || e.name || '').toLowerCase().includes(q) ||
      (e.description || '').toLowerCase().includes(q) ||
      (e.location || e.city || '').toLowerCase().includes(q)
    )
  }

  if (selectedCategory.value && selectedCategory.value !== 'All') {
    result = result.filter(e => (e.category || '').toLowerCase() === selectedCategory.value.toLowerCase())
  }

  if (selectedDate.value) {
    result = result.filter(e => {
      const eventDate = e.startDate ? new Date(e.startDate).toISOString().split('T')[0] : 
                        e.datestart ? new Date(e.datestart * 1000).toISOString().split('T')[0] : null
      return eventDate === selectedDate.value
    })
  }

  return result
})

async function loadEvents() {
  loading.value = true
  message.value = ''
  try {
    const { data } = await useFetch<EventItem[]>(`/api/events`, {
      query: { page: page.value, size: size.value }
    })
    events.value = data.value || []
  } catch (e: any) {
    message.value = e?.statusMessage || 'Failed to load events.'
  } finally {
    loading.value = false
  }
}

function clearFilters() {
  searchQuery.value = ''
  selectedCategory.value = ''
  selectedDate.value = ''
}

onMounted(loadEvents)
</script>

<template>
  <div class="bg-white rounded shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-16">
      
      <!-- Search and Filters Section (Eventpop-like) -->
      <section class="mb-12">
        <div class="text-center mb-8">
          <h2 class="text-3xl sm:text-4xl font-bold text-gray-900 tracking-tight">
            Discover Events
          </h2>
          <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-500">
            Find your next experience
          </p>
        </div>

        <!-- Search Bar -->
        <div class="max-w-3xl mx-auto mb-6">
          <div class="relative">
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="Search events by name, location, or description..." 
              class="w-full px-6 py-4 pr-12 text-lg border-2 border-gray-300 rounded-full focus:outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-all"
            />
            <button class="absolute right-2 top-1/2 transform -translate-y-1/2 bg-violet-600 text-white p-3 rounded-full hover:bg-violet-700 transition-colors">
              🔍
            </button>
          </div>
        </div>

        <!-- Category Filters -->
        <div class="flex flex-wrap justify-center gap-3 mb-6">
          <button 
            v-for="cat in categories" 
            :key="cat"
            @click="selectedCategory = cat === 'All' ? '' : cat"
            :class="[
              'px-6 py-2 rounded-full font-semibold transition-all',
              (cat === 'All' && !selectedCategory) || selectedCategory === cat
                ? 'bg-violet-600 text-white shadow-lg'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            {{ cat }}
          </button>
        </div>

        <!-- Date Filter and Clear -->
        <div class="flex flex-wrap justify-center gap-4 items-center">
          <div class="flex items-center gap-2">
            <label class="text-gray-700 font-semibold">Date:</label>
            <input 
              v-model="selectedDate" 
              type="date" 
              class="px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-violet-500"
            />
          </div>
          <button 
            v-if="searchQuery || selectedCategory || selectedDate"
            @click="clearFilters"
            class="px-4 py-2 bg-red-100 text-red-600 rounded-lg font-semibold hover:bg-red-200 transition-colors"
          >
            Clear Filters
          </button>
        </div>
      </section>

      <hr class="border-gray-200 my-8" />

      <!-- Events Grid -->
      <section class="my-16">
        <div class="text-center mb-8">
          <h2 class="text-3xl sm:text-4xl font-bold text-gray-900 tracking-tight">
            Upcoming Events
          </h2>
          <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-500">
            {{ filteredEvents.length }} event(s) found
          </p>
        </div>
        
        <div v-if="loading" class="mt-6 text-center text-gray-500">Loading events…</div>
        <div v-else-if="!filteredEvents.length" class="mt-6 text-center text-gray-500">
          <p class="text-xl mb-4">No events found matching your criteria</p>
          <button @click="clearFilters" class="text-violet-600 underline hover:text-violet-800">Clear filters and try again</button>
        </div>
        <div v-else class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-8">
          <div v-for="event in filteredEvents" :key="event.id">
            <ProductCard :event="event" />
          </div>
        </div>
      </section>
      
    </div>
  </div>
</template>