<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { $fetch } from 'ofetch'
import Login from '~/components/Login.vue' // Assuming you have these components
import Register from '~/components/Register.vue'

type EventItem = any

// --- STATE ---
const events = ref<EventItem[]>([])
const loading = ref(true)
const message = ref('')
const showLoginModal = ref(false)

// --- FILTERS ---
const searchQuery = ref('')
const selectedFilter = ref('All')
const filters = ['All', 'Today', 'Tomorrow', 'This Weekend', 'Free']

// --- COMPUTED PROPERTIES ---
const filteredEvents = computed(() => {
  let result = events.value

  // 1. Search Query Filter
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(e => 
      (e.title || e.name || '').toLowerCase().includes(q) ||
      (e.description || '').toLowerCase().includes(q) ||
      (e.location || e.city || '').toLowerCase().includes(q)
    )
  }
  
  // 2. Date/Free Filter
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
  const tomorrow = today + 24 * 60 * 60 * 1000
  
  if (selectedFilter.value === 'Today') {
    result = result.filter(e => {
        const eventDate = new Date(e.startDate || e.datestart).setHours(0,0,0,0);
        return eventDate === today;
    });
  } else if (selectedFilter.value === 'Tomorrow') {
     result = result.filter(e => {
        const eventDate = new Date(e.startDate || e.datestart).setHours(0,0,0,0);
        return eventDate === tomorrow;
    });
  } else if (selectedFilter.value === 'Free') {
    result = result.filter(e => (e.ticketPrice || 0) === 0)
  }

  return result
})

// --- FUNCTIONS ---
async function loadEvents() {
  loading.value = true
  message.value = ''
  try {
    const data = await $fetch<EventItem[]>('/api/events/json')
    events.value = data || []
    if (!events.value.length) {
        message.value = "No events are available at the moment."
    }
  } catch (e: any) {
    message.value = e?.statusMessage || 'Failed to load events.'
    console.error('Error loading events:', e)
  } finally {
    loading.value = false
  }
}

function formatDateForCard(dateString: string) {
    if (!dateString) return { month: 'TBA', day: '' };
    const date = new Date(dateString);
    return {
        month: date.toLocaleString('en-US', { month: 'short' }).toUpperCase(),
        day: date.getDate()
    };
}

onMounted(loadEvents)
</script>

<template>
  <div class="bg-white text-gray-800">
    <!-- Login Modal (from original index.vue) -->
    <transition name="fade">
      <div v-if="showLoginModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4" @click.self="showLoginModal = false">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full">
          <Login @close="showLoginModal = false" />
        </div>
      </div>
    </transition>
    
    <main>
      <!-- Categories Section (from eventspage) -->
      <section class="container mx-auto px-4 py-12">
        <h2 class="text-3xl font-bold mb-8">Explore Categories</h2>
        <div class="grid grid-cols-3 md:grid-cols-6 gap-5 md:gap-8">
          <div class="text-center group cursor-pointer">
            <img src="https://picsum.photos/id/1011/200/200" alt="Entertainment" class="w-24 h-24 md:w-32 md:h-32 mx-auto rounded-full object-cover mb-3 transition-transform duration-300 group-hover:scale-105 shadow-md">
            <p class="font-semibold">Entertainment</p>
          </div>
          <div class="text-center group cursor-pointer">
            <img src="https://picsum.photos/id/1076/200/200" alt="Educational" class="w-24 h-24 md:w-32 md:h-32 mx-auto rounded-full object-cover mb-3 transition-transform duration-300 group-hover:scale-105 shadow-md">
            <p class="font-semibold">Educational</p>
          </div>
          <div class="text-center group cursor-pointer">
            <img src="https://picsum.photos/id/10/200/200" alt="Arts" class="w-24 h-24 md:w-32 md:h-32 mx-auto rounded-full object-cover mb-3 transition-transform duration-300 group-hover:scale-105 shadow-md">
            <p class="font-semibold">Cultural & Arts</p>
          </div>
          <div class="text-center group cursor-pointer">
            <img src="https://picsum.photos/id/146/200/200" alt="Sports" class="w-24 h-24 md:w-32 md:h-32 mx-auto rounded-full object-cover mb-3 transition-transform duration-300 group-hover:scale-105 shadow-md">
            <p class="font-semibold">Sports & Fitness</p>
          </div>
          <div class="text-center group cursor-pointer">
            <img src="https://picsum.photos/id/180/200/200" alt="Technology" class="w-24 h-24 md:w-32 md:h-32 mx-auto rounded-full object-cover mb-3 transition-transform duration-300 group-hover:scale-105 shadow-md">
            <p class="font-semibold">Technology</p>
          </div>
          <div class="text-center group cursor-pointer">
            <img src="https://picsum.photos/id/20/200/200" alt="Travel" class="w-24 h-24 md:w-32 md:h-32 mx-auto rounded-full object-cover mb-3 transition-transform duration-300 group-hover:scale-105 shadow-md">
            <p class="font-semibold">Travel</p>
          </div>
        </div>
      </section>

      <!-- Popular Events Section (from eventspage) -->
      <section class="bg-gray-50 py-16">
        <div class="container mx-auto px-4">
          <h2 class="text-3xl font-bold mb-8">Popular Events</h2>
          
          <div class="flex gap-2 md:gap-4 mb-8 overflow-x-auto pb-2 -mx-4 px-4">
            <button
              v-for="filter in filters"
              :key="filter"
              @click="selectedFilter = filter"
              class="px-5 py-2 rounded-full font-semibold text-sm transition-colors whitespace-nowrap"
              :class="selectedFilter === filter ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-200 border'"
            >
              {{ filter }}
            </button>
          </div>
          
          <div v-if="loading" class="text-center text-gray-500 py-12">
            Loading events...
          </div>

          <div v-else-if="!filteredEvents.length" class="text-center text-gray-500 bg-white border-2 border-dashed rounded-lg p-12">
              <p class="font-semibold">No events found</p>
              <p v-if="selectedFilter !== 'All'">Try changing your filter.</p>
          </div>

          <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <NuxtLink 
              v-for="event in filteredEvents" 
              :key="event.id"
              :to="`/ProductPageDetail/${event.id}`"
              class="bg-white rounded-xl shadow-lg p-5 flex flex-col gap-4 border border-transparent hover:border-blue-500 transition-all transform hover:-translate-y-1"
            >
              <div class="flex justify-between items-center">
                <span class="bg-blue-500 text-white text-xs font-semibold px-3 py-1 rounded-full">{{ event.category || 'Event' }}</span>
                <button class="text-gray-400 hover:text-blue-500 text-2xl"><i class="fa-regular fa-star"></i></button>
              </div>
              <div class="flex gap-5 pt-4 border-t">
                <div class="text-center text-blue-600 shrink-0">
                  <span class="text-sm font-semibold">{{ formatDateForCard(event.startDate || event.datestart).month }}</span>
                  <span class="text-3xl font-bold block leading-none">{{ formatDateForCard(event.startDate || event.datestart).day }}</span>
                </div>
                <div class="details">
                  <h3 class="text-lg font-bold text-gray-900">{{ event.title || event.name }}</h3>
                  <p class="text-sm text-gray-500 mb-1 truncate">{{ event.description }}</p>
                  <p v-if="event.participantsCount > 0" class="text-sm text-gray-600 font-medium"><i class="fa-solid fa-star text-yellow-400"></i> {{ event.participantsCount }} Interested</p>
                </div>
              </div>
            </NuxtLink>
          </div>

          <div v-if="!loading && filteredEvents.length > 0" class="text-center mt-12">
            <button class="bg-white border-2 border-gray-300 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors">
              See More
            </button>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { 
  transition: opacity 0.3s ease; 
}

.fade-enter-from, .fade-leave-to { 
  opacity: 0; 
}
</style>