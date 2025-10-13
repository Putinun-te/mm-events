<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'

const route = useRoute()
const router = useRouter()
const { loadFromStorage, isLoggedIn } = useAuth()
const { push: toast } = useToast()

const productId = route.params.id
const event = ref<any>(null)
const loading = ref(true)
const quantity = ref(1)

// Format date helper
function formatDateTime(dateStr: string | number) {
  if (!dateStr) return 'TBA'
  const date = typeof dateStr === 'number' ? new Date(dateStr * 1000) : new Date(dateStr)
  return new Intl.DateTimeFormat('en-US', { 
    month: 'short', 
    day: '2-digit', 
    year: 'numeric',
    hour: '2-digit', 
    minute: '2-digit' 
  }).format(date)
}

const formattedStartDate = computed(() => event.value?.startDate ? formatDateTime(event.value.startDate) : (event.value?.datestart ? formatDateTime(event.value.datestart) : 'TBA'))
const formattedEndDate = computed(() => event.value?.endDate ? formatDateTime(event.value.endDate) : (event.value?.dateend ? formatDateTime(event.value.dateend) : 'TBA'))
const eventTitle = computed(() => event.value?.title || event.value?.name || 'Event')
const eventDescription = computed(() => event.value?.description || 'No description available')
const ticketPrice = computed(() => event.value?.ticketPrice || 0)
const availableSeats = computed(() => event.value?.personLimit || event.value?.personlimit || 0)
const eventLocation = computed(() => {
  if (event.value?.location) return event.value.location
  if (event.value?.city && event.value?.country) return `${event.value.city}, ${event.value.country}`
  if (event.value?.city) return event.value.city
  if (event.value?.address) return event.value.address
  return 'Location TBA'
})

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) {
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
  loadFromStorage()
  loadScript('https://api.longdo.com/map3/?key=REPLACE_WITH_MAP_API_KEY')
    .catch(error => console.error("Failed to load Longdo Map script:", error))

  loading.value = true
  // Try history state first, then fetch from JSON
  event.value = window.history.state?.event ?? null
  if (!event.value) {
    try {
      const data = await $fetch(`/api/events/json/${productId}`)
      event.value = data
    } catch (e) {
      console.error('Failed to load event', e)
      toast('Failed to load event details', 'error')
    }
  }
  loading.value = false
})

function changeQuantity(delta: number) {
  const newQty = quantity.value + delta
  if (newQty >= 1 && newQty <= (availableSeats.value || 999)) {
    quantity.value = newQty
  }
}

async function addToCart() {
  if (!isLoggedIn.value) {
    toast('Please login to book tickets', 'error')
    router.push('/LoginPage')
    return
  }
  
  const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
  if (!token) {
    toast('Please login to book tickets', 'error')
    router.push('/LoginPage')
    return
  }

  try {
    await $fetch('/api/bookings', {
      method: 'POST',
      body: {
        eventId: event.value.id,
        quantity: quantity.value
      },
      headers: { Authorization: `Bearer ${token}` }
    })
    toast(`Successfully booked ${quantity.value} ticket(s)!`, 'success')
    // Redirect to bookings page
    setTimeout(() => router.push('/MyBookingsPage'), 1500)
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to create booking'
    toast(message, 'error')
  }
}
</script>

<template>
    <div class="bg-gray-50 min-h-screen">
        <div v-if="loading" class="container mx-auto px-4 py-8 text-center">
            <p class="text-gray-500">Loading event details...</p>
        </div>
        <div v-else-if="!event" class="container mx-auto px-4 py-8 text-center">
            <p class="text-gray-500">Event not found</p>
        </div>
        <div v-else class="container mx-auto px-4 py-8 max-w-7xl">
            <div class="bg-white rounded-3xl shadow-2xl overflow-hidden">
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 p-6 lg:p-12">
                    <div class="space-y-6">
                        <div class="main-image-container rounded-2xl overflow-hidden bg-gray-100 aspect-square">
                            <img src="~/assets/img/apple.jpg" class="w-full h-full object-cover"/>
                            <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0"></div>
                        </div>
                        
                        <div class="grid">
                            <div>
                                <div id="map" style="width: 100%; height: 500px;"></div>
                            </div>
                        </div>
                    </div>

                    <div class="flex flex-col justify-between space-y-8">
                        <div class="space-y-4">
                            <div class="flex items-center gap-2">
                                <span v-if="event.category" class="px-3 py-1 bg-violet-100 text-violet-700 text-sm font-semibold rounded-full">
                                  {{ event.category }}
                                </span>
                                <span v-else class="px-3 py-1 bg-violet-100 text-violet-700 text-sm font-semibold rounded-full">Event</span>
                            </div>
                            
                            <h1 class="text-4xl lg:text-5xl font-bold text-gray-900 leading-tight">
                                {{ eventTitle }}
                            </h1>
                            
                            <p class="text-lg text-gray-600 leading-relaxed">
                                {{ eventDescription }}
                            </p>

                            <div class="grid grid-cols-1 gap-3 pt-4">
                                <div class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">📅 Start:</span>
                                    <span>{{ formattedStartDate }}</span>
                                </div>
                                <div class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">📅 End:</span>
                                    <span>{{ formattedEndDate }}</span>
                                </div>
                                <div class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">📍 Location:</span>
                                    <span>{{ eventLocation }}</span>
                                </div>
                                <div v-if="event.organizerName" class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">👤 Organizer:</span>
                                    <span>{{ event.organizerName }}</span>
                                </div>
                                <div v-if="event.phone" class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">� Contact:</span>
                                    <span>{{ event.phone }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="space-y-6">
                            <div class="flex items-baseline gap-4">
                                <h2 class="text-4xl font-bold text-green-600">${{ ticketPrice }}</h2>
                                <span class="text-gray-500">per ticket</span>
                            </div>
                            
                            <div class="flex items-center gap-3">
                                <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
                                <span class="text-green-600 font-semibold">{{ availableSeats }} seats available</span>
                            </div>
                        </div>

                        <div class="space-y-6">
                            <div class="flex items-center gap-4">
                                <label class="text-gray-700 font-semibold">Tickets:</label>
                                <div class="flex items-center border-2 border-gray-300 rounded-lg overflow-hidden">
                                    <button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 transition-colors" @click="changeQuantity(-1)">-</button>
                                    <span class="px-6 py-2 bg-white font-semibold">{{ quantity }}</span>
                                    <button class="px-4 py-2 bg-gray-100 hover:bg-gray-200 transition-colors" @click="changeQuantity(1)">+</button>
                                </div>
                            </div>

                            <div class="flex flex-col sm:flex-row gap-4">
                                <button class="flex-1 bg-gradient-to-r from-violet-600 to-purple-600 text-white px-8 py-4 rounded-xl font-semibold text-lg hover:shadow-lg transform hover:scale-105 transition-all duration-200" @click="addToCart">
                                    🎫 Book Tickets
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>