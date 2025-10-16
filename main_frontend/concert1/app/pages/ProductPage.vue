<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import ProductTag from '~/components/ProductTag.vue'

type EventItem = any

const events = ref<EventItem[]>([])
const loading = ref(false)
const message = ref('')
const today = new Date ()

const page = ref(0)
const size = ref(12)

// Filters
const searchQuery = ref('')
const selectedCategory = ref('')
const selectedDate = ref('')


const categories = ['All', 'Rock', 'Pop', 'Jazz', 'EDM']

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
    console.log('test')
    result = result.filter(e => {
      const eventDate = e.startDate ? new Date(e.startDate).toISOString().split('T')[0] : 
                        e.datestart ? new Date(e.datestart * 1000).toISOString().split('T')[0] : null
      return eventDate === selectedDate.value
    })
  } 
  // else {
  //   console.log('hello')
  //   // mm/dd//yyyy
  //   console.log(today.getFullYear())
  //   console.log(selectedDate.value)
  //   console.log((Date.now()))
  //   const ty = today.getFullYear()
  //   const tm = String(today.getMonth() + 1).padStart(2, "0")
  //   const td = String(today.getDay() + 12).padStart(2, "0")
  //   selectedDate.value = "2025-10-16"
  //   selectedDate.value = `${ty}-${tm}-${td}`
  // }

  return result
})

async function loadEvents() {
  loading.value = true
  message.value = ''
  try {
    // Load events from JSON file
    const data = await $fetch<EventItem[]>('/api/events/json')
    events.value = data || []
  } catch (e: any) {
    message.value = e?.statusMessage || 'Failed to load events.'
    console.error('Error loading events:', e)
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
            <svg 
              class="absolute left-5 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400"
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="Search events by name, location, or description..." 
              class="w-full pl-14 pr-24 py-4 text-lg border-2 border-gray-300 rounded-full focus:outline-none focus:border-violet-500 focus:ring-2 focus:ring-violet-200 transition-all"
            />
            <button 
              v-if="searchQuery"
              @click="searchQuery = ''"
              class="absolute right-16 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 p-2 rounded-full hover:bg-gray-100 transition-all"
              aria-label="Clear search"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
            <button class="absolute right-2 top-1/2 transform -translate-y-1/2 bg-violet-600 text-white p-3 rounded-full hover:bg-violet-700 transition-colors">
              Search
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
            <span v-if="loading">Loading events...</span>
            <span v-else-if="searchQuery || selectedCategory || selectedDate">
              {{ filteredEvents.length}} result{{ filteredEvents.length !== 1 ? 's' : '' }} found
              <span v-if="searchQuery" class="font-semibold text-violet-600">
                for "{{ searchQuery }}"
              </span>
            </span>
            <span v-else>
              {{ filteredEvents.length }} event{{ filteredEvents.length !== 1 ? 's' : '' }} available
            </span>
          </p>
        </div>
        
        <!-- Loading Skeletons -->
        <div v-if="loading" class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-8">
          <EventCardSkeleton v-for="n in 8" :key="n" />
        </div>

        <!-- Empty State -->
        <EmptyState
          v-else-if="!filteredEvents.length && (searchQuery || selectedCategory || selectedDate)"
          type="no-search-results"
          title="No events found"
          :description="`No events match your search criteria. Try adjusting your filters or browse all events.`"
          actionText="Browse All Events"
          :actionLink="'/concert/ProductPage'"
          :secondaryAction="true"
          secondaryText="Clear Filters"
          @secondary-action="clearFilters"
        />

        <EmptyState
          v-else-if="!filteredEvents.length"
          type="no-events"
          title="No events yet"
          description="There are no events available at the moment. Check back soon or create your own event!"
          actionText="Create Event"
          :actionLink="'/concert/CreateEventPage'"
        />

        <!-- Events Grid -->
        <div v-else class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-8">
          <div v-for="event in filteredEvents" :key="event.id">
            <ProductCard :event="event" />
          </div>
        </div>
      </section>
      
    </div>
  </div>
</template>