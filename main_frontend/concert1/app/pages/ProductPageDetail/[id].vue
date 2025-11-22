<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'
import { useApi } from '~/composables/useApi'

const PLACEHOLDER_IMAGE = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><rect width="256" height="256" rx="24" fill="%23e2e8f0"/><text x="50%25" y="52%25" dominant-baseline="middle" text-anchor="middle" font-family="Arial,Helvetica,sans-serif" font-size="36" fill="%234a5568">Event</text></svg>'

// definePageMeta removed - not available in plain Vue.js context

const route = useRoute()
const router = useRouter()
const { loadFromStorage, isLoggedIn } = useAuth()
const { success, error } = useToast()
const { apiFetch } = useApi()

const productId = route.params.id
const event = ref<any>(null)
const loading = ref(true)
const quantity = ref(1)

const totalPrice = computed(() => {
  return (ticketPrice.value * quantity.value).toFixed(2)
})

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

const organizerDisplayName = computed(() => {
  return event.value?.organizer?.displayName || event.value?.organizerName || ''
})

const organizerId = computed(() => {
  return event.value?.organizer?.id || event.value?.organizerId || null
})

const organizerUsername = computed(() => {
  return event.value?.organizer?.username || event.value?.organizerUsername || ''
})

const participantsCount = computed(() => event.value?.participantsCount || 0)
const participants = computed(() => event.value?.participants || [])
const spotsRemaining = computed(() => {
  const limit = availableSeats.value
  if (limit <= 0) return 'Unlimited'
  const remaining = limit - participantsCount.value
  return remaining > 0 ? remaining : 0
})

const eventPhotoUrl = computed(() => {
  const value = event.value?.photoUrl
  if (value && typeof value === 'string' && value.length > 0 && !value.includes('null')) {
    return value
  }
  return PLACEHOLDER_IMAGE
})

const isEventFull = computed(() => {
  const limit = availableSeats.value
  if (limit <= 0) return false
  return participantsCount.value >= limit
})

const actualAvailableSeats = computed(() => {
  const limit = availableSeats.value
  if (limit <= 0) return 999
  const remaining = limit - participantsCount.value
  return remaining > 0 ? remaining : 0
})

onMounted(async () => {
  loadFromStorage()
  loading.value = true
  
  event.value = window.history.state?.event ?? null
  if (!event.value) {
    let backendData: any = null
    let jsonData: any = null
    
    try {
      backendData = await apiFetch(`/api/events/${productId}`)
    } catch (backendError) {
      console.warn('Backend event lookup failed, falling back to JSON source', backendError)
    }

    try {
      jsonData = await apiFetch(`/api/events/json/${productId}`)
    } catch (jsonError) {
      if (!backendData) {
        console.error('Failed to load event', jsonError)
        error('Failed to load event details', 'Error')
      }
    }

    if (backendData || jsonData) {
      event.value = {
        ...(jsonData || {}),
        ...(backendData || {}),
        photoUrl: backendData?.photoUrl ?? jsonData?.photoUrl ?? null,
        photoId: backendData?.photoId ?? jsonData?.photoId ?? null
      }
    }
  }
  loading.value = false
})

const changeQuantity = (delta: number) => {
  const newQuantity = quantity.value + delta;
  const maxAllowed = actualAvailableSeats.value;
  if (newQuantity >= 1 && newQuantity <= maxAllowed) {
    quantity.value = newQuantity;
  }
};

async function addToCart() {
  if (isEventFull.value) {
    error('This event is full. No more tickets available.', 'Event Full')
    return
  }

  if (quantity.value > actualAvailableSeats.value) {
    error(`Only ${actualAvailableSeats.value} seat${actualAvailableSeats.value !== 1 ? 's' : ''} remaining. Please reduce your quantity.`, 'Insufficient Seats')
    quantity.value = actualAvailableSeats.value
    return
  }

  if (!isLoggedIn.value) {
    error('Please login to book tickets', 'Authentication Required')
    router.push('/LoginPage')
    return
  }

  if (!event.value?.id) {
    error('Event ID is missing', 'Booking Failed')
    return
  }

  try {
    // Use direct fetch to bypass any issues with apiFetch
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    
    const response = await fetch('https://vg3ht9p21k.execute-api.ap-southeast-1.amazonaws.com/api/bookings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        eventId: String(event.value.id),
        quantity: Number(quantity.value)
      })
    })
    
    if (!response.ok) {
      const errorText = await response.text()
      console.error('Booking failed:', response.status, errorText)
      throw new Error(`HTTP ${response.status}: ${errorText}`)
    }
    
    const result = await response.json()
    console.log('Booking successful:', result)
    success(`Successfully booked ${quantity.value} ticket(s)!`, 'Booking Confirmed')
    setTimeout(() => router.push('/MyBookingsPage'), 1500)
  } catch (e: any) {
    console.error('Booking error:', e)
    if (e.message.includes('401')) {
      error('Please login again', 'Session Expired')
      router.push('/LoginPage')
    } else {
      error('Booking failed. Please try again.', 'Error')
    }
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
              <img :src="eventPhotoUrl" class="w-full h-full object-cover"/>
                            <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0"></div>
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
                <div v-if="organizerDisplayName" class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">👤 Organizer:</span>
                  <span>{{ organizerDisplayName }}</span>
                                </div>
                <div v-if="organizerUsername" class="flex items-center gap-3 text-gray-700">
                  <span class="font-semibold">@ Username:</span>
                  <span>{{ organizerUsername }}</span>
                </div>
                <div v-if="organizerId" class="flex items-center gap-3 text-gray-700">
                  <span class="font-semibold">🆔 User ID:</span>
                  <span>{{ organizerId }}</span>
                </div>
                                <div v-if="event.phone" class="flex items-center gap-3 text-gray-700">
                                    <span class="font-semibold">📞 Contact:</span>
                                    <span>{{ event.phone }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="space-y-6">
                            <div class="flex items-baseline gap-4">
                                <h2 class="text-4xl font-bold text-green-600">${{ ticketPrice }}</h2>
                                <span class="text-gray-500">per ticket</span>
                            </div>
                            
                            <div v-if="isEventFull" class="flex items-center gap-3">
                                <div class="w-3 h-3 bg-red-400 rounded-full animate-pulse"></div>
                                <span class="text-red-600 font-semibold">Event Full - No seats available</span>
                            </div>
                            <div v-else-if="actualAvailableSeats < 10" class="flex items-center gap-3">
                                <div class="w-3 h-3 bg-orange-400 rounded-full animate-pulse"></div>
                                <span class="text-orange-600 font-semibold">Only {{ actualAvailableSeats }} seat{{ actualAvailableSeats !== 1 ? 's' : '' }} left!</span>
                            </div>
                            <div v-else class="flex items-center gap-3">
                                <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
                                <span class="text-green-600 font-semibold">{{ actualAvailableSeats }} seats available</span>
                            </div>
                            
                            <div class="bg-violet-50 rounded-xl p-4 space-y-2">
                                <div class="flex items-center justify-between">
                                    <span class="text-gray-700 font-semibold">👥 Participants:</span>
                                    <span class="text-violet-600 font-bold">{{ participantsCount }} / {{ availableSeats || '∞' }}</span>
                                </div>
                                <div v-if="spotsRemaining !== 'Unlimited'" class="w-full bg-gray-200 rounded-full h-2">
                                    <div 
                                        class="h-2 rounded-full transition-all duration-300"
                                        :class="isEventFull ? 'bg-gradient-to-r from-red-500 to-orange-500' : 'bg-gradient-to-r from-violet-500 to-purple-500'"
                                        :style="{ width: `${Math.min((participantsCount / availableSeats) * 100, 100)}%` }"
                                    ></div>
                                </div>
                                <p v-if="isEventFull" class="text-sm font-semibold text-red-600">
                                    🚫 Event is full
                                </p>
                                <p v-else-if="spotsRemaining !== 'Unlimited'" class="text-sm text-gray-600">
                                    {{ spotsRemaining }} spot{{ spotsRemaining !== 1 ? 's' : '' }} remaining
                                </p>
                                <p v-else class="text-sm text-gray-600">Unlimited spots available</p>
                            </div>
                        </div>

                        <div class="space-y-6">
                            <div v-if="!isEventFull" class="space-y-2">
                                <label class="text-gray-700 font-semibold block">Number of Tickets:</label>
                                <div class="flex items-center gap-4">
                                    <div class="flex items-center border-2 border-gray-300 rounded-lg bg-white shadow-sm">
                                        <button 
                                            type="button"
                                            class="px-6 py-3 bg-gray-100 hover:bg-gray-200 active:bg-gray-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-bold text-xl"
                                            @click="changeQuantity(-1)"
                                            :disabled="quantity <= 1"
                                            style="z-index: 100; position: relative;"
                                        >−</button>
                                        <input 
                                            type="number"
                                            v-model.number="quantity"
                                            :min="1"
                                            :max="actualAvailableSeats"
                                            class="w-20 text-center py-3 font-semibold text-lg border-0 focus:outline-none focus:none focus:ring-2 focus:ring-violet-500"
                                        />
                                        <button 
                                            type="button"
                                            class="px-6 py-3 bg-gray-100 hover:bg-gray-200 active:bg-gray-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-bold text-xl"
                                            @click="changeQuantity(1)"
                                            :disabled="quantity >= actualAvailableSeats"
                                            style="z-index: 100; position: relative;"
                                        >+</button>
                                    </div>
                                    <span class="text-sm text-gray-500">
                                        Max {{ actualAvailableSeats }} per booking
                                    </span>
                                </div>
                            </div>

                            <div v-if="!isEventFull" class="bg-gradient-to-r from-green-50 to-teal-50 rounded-xl p-4 border-2 border-green-200">
                                <div class="flex justify-between items-center">
                                    <div>
                                        <p class="text-sm text-gray-600">Total Price</p>
                                        <p class="text-3xl font-bold text-green-600">${{ totalPrice }}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-sm text-gray-600">{{ quantity }} ticket{{ quantity > 1 ? 's' : '' }}</p>
                                        <p class="text-sm text-gray-500">${{ ticketPrice }} each</p>
                                    </div>
                                </div>
                            </div>

                            <div class="flex flex-col sm:flex-row gap-4">
                                <button 
                                    v-if="isEventFull"
                                    disabled
                                    class="flex-1 bg-gray-400 text-white px-8 py-4 rounded-xl font-semibold text-lg cursor-not-allowed opacity-60"
                                >
                                    🚫 Event Full - No Seats Available
                                </button>
                                <button 
                                    v-else
                                    class="flex-1 bg-gradient-to-r from-green-600 to-teal-600 text-white px-8 py-4 rounded-xl font-semibold text-lg hover:shadow-lg transform hover:scale-105 transition-all duration-200" 
                                    @click="addToCart"
                                >
                                    🎫 Book {{ quantity }} Ticket{{ quantity > 1 ? 's' : '' }} - ${{ totalPrice }}
                                </button>
                            </div>
                            
                            <p v-if="!isEventFull" class="text-sm text-gray-500 text-center">
                                💡 Need more tickets? You can book multiple times!
                            </p>
                            <p v-else class="text-sm text-red-500 text-center font-semibold">
                                ⚠️ This event has reached maximum capacity
                            </p>
                            
                            <div v-if="participants.length > 0" class="mt-6 bg-gradient-to-br from-violet-50 to-purple-50 rounded-xl p-6 border border-violet-200">
                                <div class="flex items-center justify-between mb-4">
                                    <h3 class="text-lg font-bold text-gray-900 flex items-center gap-2">
                                        <span>👥</span>
                                        <span>Participants</span>
                                    </h3>
                                    <div class="bg-violet-600 text-white px-3 py-1 rounded-full text-sm font-semibold">
                                        {{ participantsCount }} tickets booked
                                    </div>
                                </div>
                                <div class="max-h-60 overflow-y-auto space-y-2">
                                    <div 
                                        v-for="participant in participants" 
                                        :key="participant.userName"
                                        class="flex items-center justify-between bg-white rounded-lg p-3 hover:shadow-md transition-all border border-violet-100"
                                    >
                                        <div class="flex items-center gap-3">
                                            <div class="w-10 h-10 rounded-full bg-gradient-to-br from-violet-500 to-purple-500 flex items-center justify-center text-white font-bold text-sm shadow-md">
                                                {{ participant.userName?.charAt(0)?.toUpperCase() || 'U' }}
                                            </div>
                                            <div>
                                                <p class="font-semibold text-gray-900">{{ participant.userName || 'Anonymous' }}</p>
                                                <p class="text-xs text-gray-500">
                                                    Joined {{ new Date(participant.joinedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}
                                                </p>
                                            </div>
                                        </div>
                                        <div class="flex items-center gap-2">
                                            <span class="bg-green-100 text-green-700 px-3 py-1 rounded-full text-xs font-semibold">
                                                🎫 {{ participant.ticketCount || 1 }} ticket{{ (participant.ticketCount || 1) > 1 ? 's' : '' }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div v-else class="mt-6 bg-gray-50 rounded-xl p-8 text-center border-2 border-dashed border-gray-300">
                                <div class="w-16 h-16 bg-gray-200 rounded-full flex items-center justify-center mx-auto mb-3">
                                    <span class="text-3xl">👥</span>
                                </div>
                                <p class="text-gray-600 font-semibold mb-1">No participants yet</p>
                                <p class="text-sm text-gray-500">Be the first to join this event!</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>