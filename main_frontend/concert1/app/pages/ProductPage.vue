<template>
  <div class="product-page">
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Products</h1>
      
      <!-- Search and Filters -->
      <div class="mb-8 space-y-4">
        <input 
          v-model="searchQuery"
          type="text"
          placeholder="Search events..."
          class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        
        <div class="flex gap-4">
          <select 
            v-model="selectedCategory"
            class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="All">All Categories</option>
            <option value="Music">Music</option>
            <option value="Sports">Sports</option>
            <option value="Tech">Tech</option>
            <option value="Art">Art</option>
          </select>
          
          <input 
            v-model="selectedDate"
            type="date"
            class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          
          <button 
            @click="clearFilters"
            class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
          >
            Clear Filters
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-12">
        <p class="text-gray-500">Loading products...</p>
      </div>

      <!-- Error Message -->
      <div v-else-if="message" class="text-center py-12">
        <p class="text-red-600">{{ message }}</p>
      </div>

      <!-- Products Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div 
          v-for="product in filteredEvents" 
          :key="product.id"
          class="product-card bg-white rounded-lg shadow-lg overflow-hidden hover:shadow-xl transition-shadow cursor-pointer"
          @click="navigateToDetail(product.id)"
        >
          <img 
            :src="product.posterUrl || product.image || '/img/product-placeholder.jpg'" 
            :alt="product.title || product.name"
            class="w-full h-48 object-cover"
          />
          <div class="p-6">
            <h3 class="text-xl font-bold mb-2">{{ product.title || product.name }}</h3>
            <p class="text-gray-600 mb-4">{{ product.description }}</p>
            <div class="flex items-center justify-between">
              <span class="text-2xl font-bold text-green-600">${{ product.price || product.ticketPrice || 0 }}</span>
              <span class="text-sm text-gray-500">{{ product.location || product.city }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="!loading && !message && filteredEvents.length === 0" class="text-center py-12">
        <p class="text-gray-500">No products found</p>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const events = ref<any[]>([])
const loading = ref(true)
const message = ref('')
const searchQuery = ref('')
const selectedCategory = ref('All')
const selectedDate = ref('')
const searchTerm = ref('')

const filteredEvents = computed(() => {
  let filtered = events.value

  // Filter by search query
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(event => {
      const title = (event.title || event.name || '').toLowerCase()
      const description = (event.description || '').toLowerCase()
      const location = (event.location || '').toLowerCase()
      const city = (event.city || '').toLowerCase()
      
      return title.includes(query) || 
             description.includes(query) || 
             location.includes(query) || 
             city.includes(query)
    })
  }

  // Filter by category
  if (selectedCategory.value && selectedCategory.value !== 'All') {
    filtered = filtered.filter(event => event.category === selectedCategory.value)
  }

  // Filter by date
  if (selectedDate.value) {
    filtered = filtered.filter(event => {
      if (event.startDate) {
        const eventDate = new Date(event.startDate).toISOString().split('T')[0]
        return eventDate === selectedDate.value
      } else if (event.datestart) {
        // Handle epoch timestamp
        const eventDate = new Date(event.datestart * 1000).toISOString().split('T')[0]
        return eventDate === selectedDate.value
      }
      return false
    })
  }

  return filtered
})

onMounted(async () => {
  await loadEvents()
})

const loadEvents = async () => {
  loading.value = true
  message.value = ''
  
  try {
    const response = await $fetch('/api/events')
    events.value = Array.isArray(response) ? response : []
  } catch (error: any) {
    message.value = error?.statusMessage || 'Failed to load events.'
    events.value = []
  } finally {
    loading.value = false
  }
}

const clearFilters = () => {
  searchQuery.value = ''
  selectedCategory.value = 'All'
  selectedDate.value = ''
  searchTerm.value = ''
}

const navigateToDetail = (id: number) => {
  router.push(`/concert/product/${id}`)
}
</script>
