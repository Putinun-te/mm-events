<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuth } from '~/composables/useAuth'

const route = useRoute()
const router = useRouter()
const { isLoggedIn } = useAuth()

const productId = route.params.id
const event = ref<any>(null)
const isLoading = ref(true)
const registrationCount = ref(1)

const spotsRemaining = computed(() => {
  if (!event.value) return 0
  const registered = event.value.registeredCount || 0
  return event.value.personlimit - registered
})

const percentageFilled = computed(() => {
  if (!event.value) return 0
  const registered = event.value.registeredCount || 0
  return Math.round((registered / event.value.personlimit) * 100)
})

const formatDate = (timestamp: string) => {
  const date = new Date(parseInt(timestamp) * 1000)
  return date.toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
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

onMounted(async () => {
  event.value = window.history.state?.event ?? null
  if (!event.value) {
    try {
      const { data } = await useFetch(`/api/product/${productId}`)
      event.value = data.value
    } catch (error) {
      console.error('Failed to load event:', error)
    }
  }
  isLoading.value = false
})

const handleRegister = () => {
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
    return
  }
  console.log(`Registering ${registrationCount.value} person(s) for event`, event.value?.id)
}

const shareEvent = async () => {
  if (navigator.share) {
    try {
      await navigator.share({
        title: event.value?.name,
        text: event.value?.description,
        url: window.location.href
      })
    } catch (error) {
      console.log('Error sharing:', error)
    }
  }
}

const changeQuantity = (delta: number) => {
  const newValue = registrationCount.value + delta
  if (newValue >= 1 && newValue <= spotsRemaining.value) {
    registrationCount.value = newValue
  }
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-purple-50">
    <div v-if="isLoading" class="max-w-7xl mx-auto px-4 py-12">
      <div class="animate-pulse space-y-8">
        <div class="h-96 bg-gray-300 rounded-3xl"></div>
        <div class="h-12 bg-gray-300 rounded w-3/4"></div>
        <div class="h-6 bg-gray-200 rounded w-1/2"></div>
      </div>
    </div>

    <div v-else-if="!event" class="max-w-7xl mx-auto px-4 py-20 text-center">
      <div class="text-6xl mb-4">😕</div>
      <h2 class="text-3xl font-bold text-gray-900 mb-4">Event Not Found</h2>
      <p class="text-gray-600 mb-8">The event you're looking for doesn't exist or has been removed.</p>
      <button @click="router.push('/ProductPage')" class="px-6 py-3 bg-purple-600 text-white font-semibold rounded-lg hover:bg-purple-700 transition-colors">
        Browse All Events
      </button>
    </div>

    <div v-else class="max-w-7xl mx-auto px-4 py-8">
      <button @click="router.back()" class="mb-6 flex items-center gap-2 text-gray-600 hover:text-gray-900 font-medium transition-colors">
        ← Back to Events
      </button>

      <div class="bg-white rounded-3xl shadow-2xl overflow-hidden">
        <div class="relative h-96 bg-gradient-to-br from-purple-500 via-pink-500 to-orange-500">
          <img src="~/assets/img/apple.jpg" alt="Event hero" class="w-full h-full object-cover opacity-90" />
          <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"></div>
          <div class="absolute bottom-8 left-8 right-8">
            <div class="flex flex-wrap gap-2 mb-4">
              <span class="px-4 py-2 bg-white/90 backdrop-blur-sm rounded-full text-sm font-bold text-gray-900 shadow-lg">
                {{ event.category || 'Event' }}
              </span>
              <span v-if="event.price" class="px-4 py-2 bg-green-500/90 backdrop-blur-sm rounded-full text-sm font-bold text-white shadow-lg">
                ${{ event.price }}
              </span>
            </div>
            <h1 class="text-4xl md:text-5xl font-bold text-white mb-2 drop-shadow-lg">
              {{ event.name }}
            </h1>
          </div>
          <button @click="shareEvent" class="absolute top-6 right-6 p-3 bg-white/90 backdrop-blur-sm rounded-full hover:bg-white transition-colors shadow-lg">
            📤
          </button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 p-8">
          <div class="lg:col-span-2 space-y-8">
            <section>
              <h2 class="text-2xl font-bold text-gray-900 mb-4">About This Event</h2>
              <p class="text-gray-700 leading-relaxed whitespace-pre-line">{{ event.description || 'No description available.' }}</p>
            </section>

            <section class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="p-6 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl">
                <div class="text-3xl mb-2">📅</div>
                <h3 class="font-bold text-indigo-900 mb-1">Date & Time</h3>
                <p class="text-sm text-indigo-700 font-semibold">{{ formatDate(event.datestart) }}</p>
                <p class="text-sm text-indigo-600">{{ formatTime(event.datestart) }} - {{ formatTime(event.dateend) }}</p>
              </div>

              <div v-if="event.location" class="p-6 bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl">
                <div class="text-3xl mb-2">📍</div>
                <h3 class="font-bold text-purple-900 mb-1">Location</h3>
                <p class="text-sm text-purple-700">{{ event.location }}</p>
                <p v-if="event.address" class="text-sm text-purple-600">{{ event.address }}</p>
              </div>

              <div class="p-6 bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl">
                <div class="text-3xl mb-2">👥</div>
                <h3 class="font-bold text-green-900 mb-1">Capacity</h3>
                <p class="text-sm text-green-700 font-semibold">{{ event.personlimit }} total spots</p>
                <p class="text-sm text-green-600">{{ spotsRemaining }} available</p>
              </div>

              <div v-if="event.phone" class="p-6 bg-gradient-to-br from-orange-50 to-amber-50 rounded-xl">
                <div class="text-3xl mb-2">📞</div>
                <h3 class="font-bold text-orange-900 mb-1">Contact</h3>
                <p class="text-sm text-orange-700">{{ event.phone }}</p>
              </div>
            </section>
          </div>

          <div class="lg:col-span-1">
            <div class="sticky top-8 bg-gradient-to-br from-purple-50 to-pink-50 rounded-2xl p-6 space-y-6 border-2 border-purple-100">
              <div>
                <div class="flex justify-between items-center mb-2">
                  <span class="text-sm font-semibold text-gray-600">Availability</span>
                  <span class="text-sm font-bold text-purple-600">{{ percentageFilled }}% filled</span>
                </div>
                <div class="h-3 bg-gray-200 rounded-full overflow-hidden">
                  <div class="h-full transition-all duration-500" :class="{'bg-red-500': percentageFilled >= 90, 'bg-orange-500': percentageFilled >= 70 && percentageFilled < 90, 'bg-green-500': percentageFilled < 70}" :style="{ width: `${percentageFilled}%` }"></div>
                </div>
                <p class="mt-2 text-sm text-gray-600">
                  <span class="font-bold text-gray-900">{{ spotsRemaining }}</span> spots remaining
                </p>
              </div>

              <div v-if="spotsRemaining > 0" class="space-y-4">
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2">Number of Tickets</label>
                  <div class="flex items-center border-2 border-purple-200 rounded-lg overflow-hidden">
                    <button @click="changeQuantity(-1)" :disabled="registrationCount <= 1" class="px-4 py-3 bg-gray-100 hover:bg-gray-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                      -
                    </button>
                    <span class="flex-1 text-center py-3 bg-white font-bold text-lg">{{ registrationCount }}</span>
                    <button @click="changeQuantity(1)" :disabled="registrationCount >= spotsRemaining" class="px-4 py-3 bg-gray-100 hover:bg-gray-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                      +
                    </button>
                  </div>
                </div>

                <div v-if="event.price" class="p-4 bg-white rounded-lg border border-purple-200">
                  <div class="flex justify-between items-center">
                    <span class="text-gray-600">Total Price:</span>
                    <span class="text-2xl font-bold text-purple-600">${{ (event.price * registrationCount).toFixed(2) }}</span>
                  </div>
                </div>

                <button @click="handleRegister" class="w-full py-4 bg-gradient-to-r from-purple-600 via-pink-600 to-orange-500 text-white font-bold rounded-xl shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200">
                  🎟️ Register Now
                </button>

                <p v-if="!isLoggedIn" class="text-center text-sm text-gray-600">
                  <NuxtLink to="/LoginPage" class="text-purple-600 hover:underline font-semibold">Sign in</NuxtLink> to complete registration
                </p>
              </div>

              <div v-else class="text-center py-6">
                <div class="text-5xl mb-3">😔</div>
                <p class="font-bold text-red-600 text-lg">Sold Out</p>
                <p class="text-sm text-gray-600 mt-2">This event has reached capacity</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>