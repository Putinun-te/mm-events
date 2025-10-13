<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'

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

const props = defineProps<{
  event: Event
}>()

const router = useRouter()
const { isLoggedIn } = useAuth()

const spotsRemaining = computed(() => {
  const registered = props.event.registeredCount || 0
  return props.event.personlimit - registered
})

const percentageFilled = computed(() => {
  const registered = props.event.registeredCount || 0
  return Math.round((registered / props.event.personlimit) * 100)
})

const statusBadge = computed(() => {
  const spots = spotsRemaining.value
  if (spots === 0) {
    return { text: 'Sold Out', class: 'bg-red-500 text-white' }
  } else if (spots <= 10) {
    return { text: `Only ${spots} left!`, class: 'bg-orange-500 text-white animate-pulse' }
  } else if (spots <= 30) {
    return { text: `${spots} spots left`, class: 'bg-yellow-500 text-gray-900' }
  } else {
    return { text: `${spots} available`, class: 'bg-green-500 text-white' }
  }
})

// Time-sensitive warning
const timeWarning = computed(() => {
  const eventDate = new Date(parseInt(props.event.datestart) * 1000)
  const now = new Date()
  const hoursUntilEvent = (eventDate.getTime() - now.getTime()) / (1000 * 60 * 60)
  
  if (hoursUntilEvent < 0) {
    return null // Event has passed
  } else if (hoursUntilEvent <= 24) {
    return { text: '⚡ Starting in < 24 hours!', class: 'bg-red-500 text-white animate-pulse' }
  } else if (hoursUntilEvent <= 48) {
    return { text: '⏰ Starting soon!', class: 'bg-orange-500 text-white' }
  }
  return null
})

// Category badge configuration
const categoryConfig = computed(() => {
  const category = props.event.category?.toLowerCase() || 'other'
  const configs: Record<string, { icon: string; color: string }> = {
    music: { icon: '🎵', color: 'bg-purple-500' },
    sports: { icon: '⚽', color: 'bg-blue-500' },
    tech: { icon: '💻', color: 'bg-indigo-500' },
    food: { icon: '🍕', color: 'bg-orange-500' },
    art: { icon: '🎨', color: 'bg-pink-500' },
    business: { icon: '💼', color: 'bg-gray-700' },
    other: { icon: '🎪', color: 'bg-gray-500' }
  }
  return configs[category] || configs.other
})

const formatDate = (timestamp: string) => {
  const date = new Date(parseInt(timestamp) * 1000)
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const formatTime = (timestamp: string) => {
  const date = new Date(parseInt(timestamp) * 1000)
  return date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  })
}

const eventDuration = computed(() => {
  const start = new Date(parseInt(props.event.datestart) * 1000)
  const end = new Date(parseInt(props.event.dateend) * 1000)
  const hours = Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60))
  return hours > 24 ? `${Math.round(hours / 24)} days` : `${hours} hours`
})

const viewDetails = () => {
  router.push(`/ProductPageDetail/${props.event.id}`)
}

const registerForEvent = () => {
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
    return
  }
  console.log('Registering for event:', props.event.id)
}

const truncatedDescription = computed(() => {
  const desc = props.event.description || ''
  return desc.length > 100 ? desc.substring(0, 100) + '...' : desc
})
</script>

<template>
  <div class="group relative bg-white rounded-2xl shadow-md hover:shadow-2xl transition-all duration-300 overflow-hidden border border-gray-100 hover:-translate-y-2">
    <div class="relative h-48 bg-gradient-to-br from-purple-500 via-pink-500 to-orange-500 overflow-hidden">
      <img src="~/assets/img/apple.jpg" alt="Event image" class="w-full h-full object-cover opacity-90 group-hover:scale-110 transition-transform duration-500" />
      
      <!-- Category Badge (Top Left) -->
      <div class="absolute top-3 left-3">
        <span :class="categoryConfig.color" class="px-3 py-1.5 rounded-full text-xs font-bold text-white shadow-lg flex items-center gap-1">
          <span>{{ categoryConfig.icon }}</span>
          <span class="capitalize">{{ event.category || 'Event' }}</span>
        </span>
      </div>

      <!-- Status Badge (Top Right) -->
      <div class="absolute top-3 right-3">
        <span :class="statusBadge.class" class="px-3 py-1.5 rounded-full text-xs font-bold shadow-lg">
          {{ statusBadge.text }}
        </span>
      </div>

      <!-- Time Warning Banner (Bottom of Image) -->
      <div v-if="timeWarning" class="absolute bottom-0 left-0 right-0">
        <div :class="timeWarning.class" class="px-4 py-2 text-xs font-bold text-center">
          {{ timeWarning.text }}
        </div>
      </div>
    </div>

    <div class="p-6">
      <h3 class="text-xl font-bold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors">
        {{ event.name }}
      </h3>
      <p class="text-gray-600 text-sm mb-4 line-clamp-2">
        {{ truncatedDescription }}
      </p>
      <div class="space-y-3 mb-4">
        <div class="flex items-start gap-2 text-sm">
          <span class="text-lg">📅</span>
          <div class="flex-1">
            <p class="font-semibold text-gray-900">{{ formatDate(event.datestart) }}</p>
            <p class="text-gray-600">{{ formatTime(event.datestart) }} - {{ formatTime(event.dateend) }}</p>
          </div>
        </div>
        <div class="flex items-center gap-2 text-sm">
          <span class="text-lg">⏱️</span>
          <span class="text-gray-600">Duration: <span class="font-semibold text-gray-900">{{ eventDuration }}</span></span>
        </div>
        <div v-if="event.location" class="flex items-start gap-2 text-sm">
          <span class="text-lg">📍</span>
          <div class="flex-1">
            <div class="inline-flex items-center gap-2 px-3 py-1 bg-gradient-to-r from-purple-50 to-pink-50 rounded-lg border border-purple-200">
              <span class="font-semibold text-purple-700">{{ event.location }}</span>
              <span class="text-purple-400">|</span>
              <span class="text-xs text-purple-600">Venue</span>
            </div>
          </div>
        </div>
      </div>
      <div class="mb-4">
        <div class="flex justify-between text-xs text-gray-600 mb-1">
          <span>{{ percentageFilled }}% filled</span>
          <span>{{ event.personlimit }} total</span>
        </div>
        <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
          <div class="h-full transition-all duration-500" :class="{'bg-red-500': percentageFilled >= 90, 'bg-orange-500': percentageFilled >= 70 && percentageFilled < 90, 'bg-green-500': percentageFilled < 70}" :style="{ width: `${percentageFilled}%` }"></div>
        </div>
      </div>
      <div class="flex gap-2">
        <button @click="viewDetails" class="flex-1 px-4 py-2.5 border-2 border-purple-600 text-purple-600 font-semibold rounded-lg hover:bg-purple-50 transition-colors duration-200">
          View Details
        </button>
        <button @click="registerForEvent" :disabled="spotsRemaining === 0" :class="{'bg-purple-600 text-white hover:bg-purple-700': spotsRemaining > 0, 'bg-gray-300 text-gray-500 cursor-not-allowed': spotsRemaining === 0}" class="flex-1 px-4 py-2.5 font-semibold rounded-lg transition-colors duration-200 disabled:opacity-50">
          {{ spotsRemaining === 0 ? 'Sold Out' : 'Register' }}
        </button>
      </div>
      <p v-if="!isLoggedIn && spotsRemaining > 0" class="text-center text-xs text-gray-500 mt-3">
        <NuxtLink to="/LoginPage" class="text-purple-600 hover:underline font-medium">Sign in</NuxtLink> to register for this event
      </p>
    </div>
  </div>
</template>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
