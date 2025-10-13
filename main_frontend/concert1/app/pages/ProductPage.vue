<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'

interface Event {
  id: string
  name: string
  datestart: string
  dateend: string
  personlimit: number
  description: string
  location?: string
  price?: number
  registeredCount?: number
  category?: string
}

const eventData = ref<Event[]>([])
const isLoading = ref(true)
const searchQuery = ref('')
const selectedCategory = ref('all')
const sortBy = ref('date')

const categories = ['all', 'music', 'sports', 'tech', 'food', 'art', 'business']

// Featured events for hero carousel
const featuredEvents = [
  {
    id: 'featured-1',
    title: 'Summer Music Festival 2025',
    subtitle: 'Experience the biggest music event of the year with world-class artists',
    image: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=1920',
    date: 'July 15-17, 2025',
    time: '6:00 PM - 11:00 PM',
    location: 'Central Park, Bangkok',
    ctaText: 'Find Tickets',
    ctaLink: '/concert/ProductPageDetail/1',
    category: 'Music Festival',
    badge: 'FEATURED EVENT'
  },
  {
    id: 'featured-2',
    title: 'Tech Innovation Summit',
    subtitle: 'Connect with industry leaders and explore cutting-edge technology',
    image: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1920',
    date: 'August 22-24, 2025',
    time: '9:00 AM - 6:00 PM',
    location: 'Convention Center, Bangkok',
    ctaText: 'Register Now',
    ctaLink: '/concert/ProductPageDetail/2',
    category: 'Technology',
    badge: 'EARLY BIRD PRICING'
  },
  {
    id: 'featured-3',
    title: 'Food & Wine Expo',
    subtitle: 'Taste exquisite cuisines from renowned chefs and world-class vineyards',
    image: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1920',
    date: 'September 10-12, 2025',
    time: '12:00 PM - 9:00 PM',
    location: 'Grand Ballroom, Bangkok',
    ctaText: 'Buy Tickets',
    ctaLink: '/concert/ProductPageDetail/3',
    category: 'Food & Beverage'
  }
]

async function fetchCartData() {
  isLoading.value = true
  try {
    const { data } = await useFetch<Event[]>(`/api/product/data`)
    if (data.value) {
      eventData.value = data.value
    }
  } catch (error) {
    console.error('Failed to fetch events:', error)
  } finally {
    isLoading.value = false
  }
}

const filteredEvents = computed(() => {
  let filtered = eventData.value

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(event =>
      event.name.toLowerCase().includes(query) ||
      event.description.toLowerCase().includes(query) ||
      event.location?.toLowerCase().includes(query)
    )
  }

  if (selectedCategory.value !== 'all') {
    filtered = filtered.filter(event => event.category === selectedCategory.value)
  }

  if (sortBy.value === 'date') {
    filtered = [...filtered].sort((a, b) => parseInt(a.datestart) - parseInt(b.datestart))
  } else if (sortBy.value === 'price') {
    filtered = [...filtered].sort((a, b) => (a.price || 0) - (b.price || 0))
  } else if (sortBy.value === 'name') {
    filtered = [...filtered].sort((a, b) => a.name.localeCompare(b.name))
  }

  return filtered
})

const eventCount = computed(() => filteredEvents.value.length)

onMounted(() => {
  fetchCartData()
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-purple-50">
    <!-- Hero Carousel Section -->
    <HeroCarousel :events="featuredEvents" :autoRotate="true" :interval="5000" />

    <!-- Search Section -->
    <div class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white py-16 px-4">
      <div class="max-w-7xl mx-auto text-center">
        <h1 class="text-5xl font-bold mb-4">Discover Amazing Events</h1>
        <p class="text-xl text-purple-100 mb-8">Find and register for events that match your interests</p>
        <div class="max-w-2xl mx-auto">
          <div class="relative">
            <span class="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 text-xl">🔍</span>
            <input v-model="searchQuery" type="text" placeholder="Search events by name, location, or description..." class="w-full pl-12 pr-4 py-4 rounded-full text-gray-900 shadow-xl focus:outline-none focus:ring-4 focus:ring-purple-300 transition-all" />
          </div>
        </div>
      </div>
    </div>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="mb-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div class="flex flex-wrap items-center gap-2">
          <button v-for="category in categories" :key="category" @click="selectedCategory = category" :class="{'bg-purple-600 text-white': selectedCategory === category, 'bg-white text-gray-700 hover:bg-gray-100': selectedCategory !== category}" class="px-4 py-2 rounded-full font-medium transition-all shadow-sm capitalize">
            {{ category }}
          </button>
        </div>
        <div class="flex items-center gap-3">
          <span class="text-sm text-gray-600 font-medium">Sort by:</span>
          <select v-model="sortBy" class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 bg-white">
            <option value="date">Date</option>
            <option value="price">Price</option>
            <option value="name">Name</option>
          </select>
        </div>
      </div>

      <div class="mb-6">
        <p class="text-gray-600">
          <span class="font-semibold text-gray-900">{{ eventCount }}</span> 
          {{ eventCount === 1 ? 'event' : 'events' }} found
        </p>
      </div>

      <div v-if="isLoading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <div v-for="i in 8" :key="i" class="bg-white rounded-2xl shadow-md overflow-hidden animate-pulse">
          <div class="h-48 bg-gray-300"></div>
          <div class="p-6 space-y-3">
            <div class="h-6 bg-gray-300 rounded w-3/4"></div>
            <div class="h-4 bg-gray-200 rounded"></div>
            <div class="h-4 bg-gray-200 rounded w-5/6"></div>
            <div class="h-10 bg-gray-300 rounded mt-4"></div>
          </div>
        </div>
      </div>

      <div v-else-if="filteredEvents.length === 0" class="text-center py-20">
        <div class="text-6xl mb-4">🔍</div>
        <h3 class="text-2xl font-bold text-gray-900 mb-2">No events found</h3>
        <p class="text-gray-600 mb-6">Try adjusting your search or filter criteria</p>
        <button @click="searchQuery = ''; selectedCategory = 'all'" class="px-6 py-3 bg-purple-600 text-white font-semibold rounded-lg hover:bg-purple-700 transition-colors">
          Clear Filters
        </button>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <div v-for="event in filteredEvents" :key="event.id">
          <ProductCard :event="event" />
        </div>
      </div>
    </div>
  </div>
</template>
