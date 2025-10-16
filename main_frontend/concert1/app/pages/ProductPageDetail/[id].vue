<script setup lang="ts">
import { ref, onMounted, onActivated, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'

const route = useRoute()
const router = useRouter()
const { loadFromStorage, isLoggedIn } = useAuth()
const { success, error } = useToast()

const productId = route.params.id
const event = ref<any>(null)
const loading = ref(true)
const quantity = ref(1)

// Computed total price
const totalPrice = computed(() => {
  return (ticketPrice.value * quantity.value).toFixed(2)
})

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

// Participants info (display only)
const participantsCount = computed(() => event.value?.participantsCount || 0)
const participants = computed(() => event.value?.participants || [])
const spotsRemaining = computed(() => {
  const limit = availableSeats.value
  if (limit <= 0) return 'Unlimited'
  const remaining = limit - participantsCount.value
  return remaining > 0 ? remaining : 0
})

// Check if event is full
const isEventFull = computed(() => {
  const limit = availableSeats.value
  if (limit <= 0) return false // Unlimited capacity
  return participantsCount.value >= limit
})

// Calculate actual available seats for booking
const actualAvailableSeats = computed(() => {
  const limit = availableSeats.value
  if (limit <= 0) return 999 // Unlimited - set to high number
  const remaining = limit - participantsCount.value
  return remaining > 0 ? remaining : 0
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

// Function to fetch event data
async function fetchEventData() {
  loading.value = true
  try {
    const data = await $fetch(`/api/events/json/${productId}`)
    event.value = data
  } catch (e) {
    console.error('Failed to load event', e)
    error('Failed to load event details', 'Error')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  loadFromStorage()
  loadScript('https://api.longdo.com/map3/?key=REPLACE_WITH_MAP_API_KEY')
    .catch(error => console.error("Failed to load Longdo Map script:", error))

  // Try history state first, then fetch from JSON
  event.value = window.history.state?.event ?? null
  if (!event.value) {
    await fetchEventData()
  } else {
    loading.value = false
  }
})

// Refresh data when page is activated (e.g., navigating back from another page)
onActivated(async () => {
  // Always refresh data to get latest participant count
  await fetchEventData()
})

const changeQuantity = (delta: number) => {
    const newQuantity = quantity.value + delta;
    const maxAllowed = actualAvailableSeats.value;
    if (newQuantity >= 1 && newQuantity <= maxAllowed) {
        quantity.value = newQuantity;
    }
};

async function addToCart() {
  // Check if event is full
  if (isEventFull.value) {
    error('This event is full. No more tickets available.', 'Event Full')
    return
  }

  // Check if requested quantity exceeds available seats
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
  
  const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
  if (!token) {
    error('Please login to book tickets', 'Authentication Required')
    router.push('/LoginPage')
    return
  }

  try {
    // Step 1: Create booking
    await $fetch('/api/bookings', {
      method: 'POST',
      body: {
        eventId: String(event.value.id),
        quantity: quantity.value,
        eventTitle: eventTitle.value,
        eventLocation: eventLocation.value,
        eventStartDate: event.value.startDate || event.value.datestart,
        ticketPrice: ticketPrice.value || 0
      },
      headers: { Authorization: `Bearer ${token}` }
    })
    
    // Step 2: Get user info (non-blocking - don't fail booking if this fails)
    let userId = null
    let userName = 'Anonymous'
    try {
      const userProfile: any = await $fetch('/api/auth/me', {
        headers: { Authorization: `Bearer ${token}` }
      })
      userId = userProfile.id
      userName = userProfile.name || userProfile.username || userProfile.email
    } catch (profileError) {
      console.warn('Failed to fetch user profile, using fallback:', profileError)
    }
    
    // Step 3: Add user to event participants (non-blocking)
    if (userId) {
      try {
        await $fetch(`/api/events/json/${event.value.id}/add-participant`, {
          method: 'POST',
          body: {
            userId,
            userName,
            ticketCount: quantity.value
          }
        })
        
        // Step 4: Reload event data to show updated participant count
        try {
          const updatedEvent = await $fetch(`/api/events/json/${event.value.id}`)
          event.value = updatedEvent
        } catch (reloadError) {
          console.warn('Failed to reload event data:', reloadError)
        }
      } catch (participantError) {
        console.warn('Failed to add participant, but booking was successful:', participantError)
      }
    }
    
    success(`Successfully booked ${quantity.value} ticket(s)!`, 'Booking Confirmed')
    
    // Redirect to bookings page
    setTimeout(() => router.push('/MyBookingsPage'), 1500)
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to create booking'
    error(message, 'Booking Failed')
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
                            <!-- Quantity Selector with better click handling -->
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

                            <!-- Total Price Display -->
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
                            
                            <!-- Participants List -->
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
                                        :key="participant.userId"
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
                            
                            <!-- Empty Participants State -->
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